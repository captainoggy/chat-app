import { getOwner } from "discourse-common/lib/get-owner";
import ChatMessagesManager from "discourse/plugins/chat/discourse/lib/chat-messages-manager";
import { escapeExpression } from "discourse/lib/utilities";
import { tracked } from "@glimmer/tracking";
import guid from "pretty-text/guid";
import ChatMessage from "discourse/plugins/chat/discourse/models/chat-message";

export const THREAD_STATUSES = {
  open: "open",
  readOnly: "read_only",
  closed: "closed",
  archived: "archived",
};

export default class ChatThread {
  static create(channel, args = {}) {
    return new ChatThread(channel, args);
  }

  @tracked id;
  @tracked title;
  @tracked status;
  @tracked draft;
  @tracked staged;
  @tracked channel;
  @tracked originalMessage;
  @tracked threadMessageBusLastId;
  @tracked replyCount;

  messagesManager = new ChatMessagesManager(getOwner(this));

  constructor(channel, args = {}) {
    this.title = args.title;
    this.id = args.id;
    this.channel = channel;
    this.status = args.status;
    this.draft = args.draft;
    this.staged = args.staged;
    this.replyCount = args.reply_count;
    this.originalMessage = ChatMessage.create(channel, args.original_message);
  }

  stageMessage(message) {
    message.id = guid();
    message.staged = true;
    message.draft = false;
    message.createdAt ??= moment.utc().format();
    message.cook();

    this.messagesManager.addMessages([message]);
  }

  get routeModels() {
    return [...this.channel.routeModels, this.id];
  }

  get messages() {
    return this.messagesManager.messages;
  }

  set messages(messages) {
    this.messagesManager.messages = messages;
  }

  get selectedMessages() {
    return this.messages.filter((message) => message.selected);
  }

  get escapedTitle() {
    return escapeExpression(this.title);
  }
}
