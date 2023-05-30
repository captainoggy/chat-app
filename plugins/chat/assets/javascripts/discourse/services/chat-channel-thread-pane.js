import ChatChannelPane from "./chat-channel-pane";
import { inject as service } from "@ember/service";

export default class ChatChannelThreadPane extends ChatChannelPane {
  @service chatChannelThreadComposer;
  @service chat;
  @service chatStateManager;

  close() {
    this.chat.activeChannel.activeThread?.messagesManager?.clearMessages();
    this.chat.activeChannel.activeThread = null;
    this.chatStateManager.closeSidePanel();
  }

  open(thread) {
    this.chat.activeChannel.activeThread = thread;
    this.chatStateManager.openSidePanel();
  }

  get selectedMessageIds() {
    return this.chat.activeChannel.activeThread.selectedMessages.mapBy("id");
  }

  get composerService() {
    return this.chatChannelThreadComposer;
  }
}
