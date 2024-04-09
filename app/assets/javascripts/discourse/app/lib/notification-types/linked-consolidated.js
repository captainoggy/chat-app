import NotificationTypeBase from "discourse/lib/notification-types/base";
import { userPath } from "discourse/lib/url";
import I18n from "discourse-i18n";

export default class extends NotificationTypeBase {
  get linkHref() {
    // Linking here for now until we have a proper new page for "linked" in the profile
    return userPath(`${this.currentUser.username}/notifications`);
  }

  get description() {
    return I18n.t("notifications.linked_consolidated_description", {
      count: this.notification.data.count,
    });
  }
}
