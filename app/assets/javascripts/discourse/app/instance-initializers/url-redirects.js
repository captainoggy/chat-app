import DiscourseURL from "discourse/lib/url";
import { initializeDefaultHomepage } from "discourse/lib/utilities";
import escapeRegExp from "discourse-common/utils/escape-regexp";

export default {
  after: "inject-objects",

  initialize(owner) {
    const currentUser = owner.lookup("service:current-user");
    if (currentUser) {
      const username = currentUser.get("username");
      const escapedUsername = escapeRegExp(username);
      DiscourseURL.rewrite(
        new RegExp(`^/u/${escapedUsername}/?$`, "i"),
        `/u/${username}/activity`
      );
    }

    // We are still using these for now
    DiscourseURL.rewrite(/^\/group\//, "/groups/");
    DiscourseURL.rewrite(/^\/groups$/, "/g");
    DiscourseURL.rewrite(/^\/groups\//, "/g/");

    // Initialize default homepage
    let siteSettings = owner.lookup("service:site-settings");
    initializeDefaultHomepage(siteSettings);
  },
};
