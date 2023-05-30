import ChatComposer from "../../chat-composer";
import { inject as service } from "@ember/service";
import I18n from "I18n";
import { action } from "@ember/object";

export default class ChatComposerThread extends ChatComposer {
  @service("chat-channel-thread-composer") composer;
  @service("chat-channel-composer") channelComposer;
  @service("chat-channel-thread-pane") pane;
  @service router;

  context = "thread";

  composerId = "thread-composer";

  get presenceChannelName() {
    return `/chat-reply/${this.args.channel.id}/thread/${this.args.thread.id}`;
  }

  get placeholder() {
    return I18n.t("chat.placeholder_thread");
  }

  get lastMessage() {
    return this.args.thread.lastMessage;
  }

  lastUserMessage(user) {
    return this.args.thread.lastUserMessage(user);
  }

  @action
  onKeyDown(event) {
    if (event.key === "Escape") {
      this.router.transitionTo(
        "chat.channel",
        ...this.args.channel.routeModels
      );
      return;
    }

    super.onKeyDown(event);
  }
}
