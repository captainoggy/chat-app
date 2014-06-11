export default Ember.ArrayController.extend(Discourse.HasCurrentUser, {
  showAdminLinks: Em.computed.alias("currentUser.staff"),

  showBookmarksLink: Em.computed.alias("currentUser.hasBookmark"),

  actions: {
    logout: function() {
      Discourse.logout();
      return false;
    }
  }
});
