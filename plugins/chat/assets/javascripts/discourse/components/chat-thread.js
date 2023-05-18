import Component from "@glimmer/component";
import { Promise } from "rsvp";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import ChatMessage from "discourse/plugins/chat/discourse/models/chat-message";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { bind, debounce } from "discourse-common/utils/decorators";
import { inject as service } from "@ember/service";
import { next, schedule } from "@ember/runloop";
import discourseLater from "discourse-common/lib/later";
import { resetIdle } from "discourse/lib/desktop-notifications";

const PAGE_SIZE = 50;

export default class ChatThreadPanel extends Component {
  @service siteSettings;
  @service currentUser;
  @service chat;
  @service router;
  @service chatApi;
  @service chatComposerPresenceManager;
  @service chatChannelThreadComposer;
  @service chatChannelThreadPane;
  @service chatChannelThreadPaneSubscriptionsManager;
  @service appEvents;
  @service capabilities;

  @tracked loading;
  @tracked uploadDropZone;

  scrollable = null;

  get thread() {
    return this.args.thread;
  }

  get channel() {
    return this.thread?.channel;
  }

  @action
  setUploadDropZone(element) {
    this.uploadDropZone = element;
  }

  @action
  subscribeToUpdates() {
    this.chatChannelThreadPaneSubscriptionsManager.subscribe(this.thread);
  }

  @action
  unsubscribeFromUpdates() {
    this.chatChannelThreadPaneSubscriptionsManager.unsubscribe();
  }

  @action
  setScrollable(element) {
    this.scrollable = element;
  }

  @action
  loadMessages() {
    const message = ChatMessage.createDraftMessage(this.channel, {
      user: this.currentUser,
    });
    message.thread = this.thread;
    message.inReplyTo = this.thread.originalMessage;
    this.chatChannelThreadComposer.message = message;

    this.thread.messagesManager.clearMessages();
    this.fetchMessages();
  }

  @action
  didResizePane() {
    this.forceRendering();
  }

  get _selfDeleted() {
    return this.isDestroying || this.isDestroyed;
  }

  @debounce(100)
  fetchMessages() {
    if (this._selfDeleted) {
      return Promise.resolve();
    }

    if (this.thread.staged) {
      this.thread.messagesManager.addMessages([this.thread.originalMessage]);
      return Promise.resolve();
    }

    this.loading = true;

    const findArgs = { pageSize: PAGE_SIZE, threadId: this.thread.id };
    return this.chatApi
      .messages(this.channel.id, findArgs)
      .then((results) => {
        if (this._selfDeleted || this.channel.id !== results.meta.channel_id) {
          this.router.transitionTo(
            "chat.channel",
            "-",
            results.meta.channel_id
          );
        }

        const [messages, meta] = this.afterFetchCallback(
          this.channel,
          this.thread,
          results
        );
        this.thread.messagesManager.addMessages(messages);
        this.thread.details = meta;
        this.markThreadAsRead();
      })
      .catch(this.#handleErrors)
      .finally(() => {
        if (this._selfDeleted) {
          return;
        }

        this.loading = false;
      });
  }

  @bind
  afterFetchCallback(channel, thread, results) {
    const messages = [];

    results.chat_messages.forEach((messageData) => {
      // If a message has been hidden it is because the current user is ignoring
      // the user who sent it, so we want to unconditionally hide it, even if
      // we are going directly to the target
      if (this.currentUser.ignored_users) {
        messageData.hidden = this.currentUser.ignored_users.includes(
          messageData.user.username
        );
      }

      messageData.expanded = !(messageData.hidden || messageData.deleted_at);
      const message = ChatMessage.create(channel, messageData);
      message.thread = thread;
      messages.push(message);
    });

    return [messages, results.meta];
  }

  // NOTE: At some point we want to do this based on visible messages
  // and scrolling; for now it's enough to do it when the thread panel
  // opens/messages are loaded since we have no pagination for threads.
  markThreadAsRead() {
    return this.chatApi.markThreadAsRead(this.channel.id, this.thread.id);
  }

  @action
  onSendMessage(message) {
    resetIdle();

    if (message.editing) {
      this.#sendEditMessage(message);
    } else {
      this.#sendNewMessage(message);
    }
  }

  @action
  resetComposer() {
    this.chatChannelThreadComposer.reset(this.channel, this.thread);
  }

  @action
  resetActiveMessage() {
    this.chat.activeMessage = null;
  }

  #sendNewMessage(message) {
    message.thread = this.thread;

    if (this.chatChannelThreadPane.sending) {
      return;
    }

    this.chatChannelThreadPane.sending = true;

    this.thread.stageMessage(message);
    this.resetComposer();

    this.scrollToBottom();

    return this.chatApi
      .sendMessage(this.channel.id, {
        message: message.message,
        in_reply_to_id: message.inReplyTo?.id,
        staged_id: message.id,
        upload_ids: message.uploads.map((upload) => upload.id),
        thread_id: this.thread.staged ? null : message.thread.id,
        staged_thread_id: this.thread.staged ? message.thread.id : null,
      })
      .catch((error) => {
        this.#onSendError(message.id, error);
      })
      .finally(() => {
        if (this._selfDeleted) {
          return;
        }
        this.chatChannelThreadPane.sending = false;
      });
  }

  #sendEditMessage(message) {
    message.cook();
    this.chatChannelThreadPane.sending = true;

    const data = {
      new_message: message.message,
      upload_ids: message.uploads.map((upload) => upload.id),
    };

    this.resetComposer();

    return this.chatApi
      .editMessage(message.channel.id, message.id, data)
      .catch(popupAjaxError)
      .finally(() => {
        this.chatChannelThreadPane.sending = false;
      });
  }

  // A more consistent way to scroll to the bottom when we are sure this is our goal
  // it will also limit issues with any element changing the height while we are scrolling
  // to the bottom
  @action
  scrollToBottom() {
    next(() => {
      schedule("afterRender", () => {
        if (!this.scrollable) {
          return;
        }

        this.scrollable.scrollTop = this.scrollable.scrollHeight + 1;
        this.forceRendering(() => {
          this.scrollable.scrollTop = this.scrollable.scrollHeight;
        });
      });
    });
  }

  // since -webkit-overflow-scrolling: touch can't be used anymore to disable momentum scrolling
  // we now use this hack to disable it
  @bind
  forceRendering(callback) {
    schedule("afterRender", () => {
      if (this._selfDeleted) {
        return;
      }

      if (!this.scrollable) {
        return;
      }

      if (this.capabilities.isIOS) {
        this.scrollable.style.overflow = "hidden";
      }

      callback?.();

      if (this.capabilities.isIOS) {
        discourseLater(() => {
          if (!this.scrollable) {
            return;
          }

          this.scrollable.style.overflow = "auto";
        }, 50);
      }
    });
  }

  @action
  resendStagedMessage() {}

  @action
  messageDidEnterViewport(message) {
    message.visible = true;
  }

  @action
  messageDidLeaveViewport(message) {
    message.visible = false;
  }

  #handleErrors(error) {
    switch (error?.jqXHR?.status) {
      case 429:
      case 404:
        popupAjaxError(error);
        break;
      default:
        throw error;
    }
  }

  #onSendError(stagedId, error) {
    const stagedMessage =
      this.thread.messagesManager.findStagedMessage(stagedId);
    if (stagedMessage) {
      if (error.jqXHR?.responseJSON?.errors?.length) {
        stagedMessage.error = error.jqXHR.responseJSON.errors[0];
      } else {
        this.chat.markNetworkAsUnreliable();
        stagedMessage.error = "network_error";
      }
    }

    this.resetComposer();
  }
}
