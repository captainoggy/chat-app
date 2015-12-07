import { exportUserArchive } from 'discourse/lib/export-csv';
import CanCheckEmails from 'discourse/mixins/can-check-emails';
import computed from 'ember-addons/ember-computed-decorators';
import UserAction from 'discourse/models/user-action';
import User from 'discourse/models/user';

export default Ember.Controller.extend(CanCheckEmails, {
  indexStream: false,
  pmView: false,
  userActionType: null,
  needs: ['user-notifications', 'user-topics-list'],

  @computed("content.username")
  viewingSelf(username) {
    return username === User.currentProp('username');
  },

  @computed('indexStream', 'viewingSelf', 'forceExpand')
  collapsedInfo(indexStream, viewingSelf, forceExpand){
    return (!indexStream || viewingSelf) && !forceExpand;
  },

  linkWebsite: Em.computed.not('model.isBasic'),

  @computed("model.trust_level")
  removeNoFollow(trustLevel) {
    return trustLevel > 2 && !this.siteSettings.tl3_links_no_follow;
  },

  @computed('viewingSelf', 'currentUser.admin')
  canSeePrivateMessages(viewingSelf, isAdmin) {
    return this.siteSettings.enable_private_messages && (viewingSelf || isAdmin);
  },

  canSeeNotificationHistory: Em.computed.alias('canSeePrivateMessages'),

  @computed("content.badge_count")
  showBadges(badgeCount) {
    return Discourse.SiteSettings.enable_badges && badgeCount > 0;
  },

  @computed("userActionType")
  privateMessageView(userActionType) {
    return (userActionType === UserAction.TYPES.messages_sent) ||
           (userActionType === UserAction.TYPES.messages_received);
  },

  @computed()
  canInviteToForum() {
    return User.currentProp('can_invite_to_forum');
  },

  canDeleteUser: Ember.computed.and("model.can_be_deleted", "model.can_delete_all_posts"),

  @computed('model.user_fields.@each.value')
  publicUserFields() {
    const siteUserFields = this.site.get('user_fields');
    if (!Ember.isEmpty(siteUserFields)) {
      const userFields = this.get('model.user_fields');
      return siteUserFields.filterProperty('show_on_profile', true).sortBy('position').map(field => {
        const value = userFields ? userFields[field.get('id').toString()] : null;
        return Ember.isEmpty(value) ? null : Ember.Object.create({ value, field });
      }).compact();
    }
  },

  privateMessagesActive: Em.computed.equal('pmView', 'index'),
  privateMessagesMineActive: Em.computed.equal('pmView', 'mine'),
  privateMessagesUnreadActive: Em.computed.equal('pmView', 'unread'),
  privateMessagesGroupsActive: Em.computed.equal('pmView', 'groups'),

  actions: {
    expandProfile() {
      this.set('forceExpand', true);
    },

    adminDelete() {
      // I really want this deferred, don't want to bring in all this code till used
      const AdminUser = require('admin/models/admin-user').default;
      AdminUser.find(this.get('model.username').toLowerCase())
                         .then(user => user.destroy({deletePosts: true}));
    },

    exportUserArchive() {
      bootbox.confirm(
        I18n.t("admin.export_csv.user_archive_confirm"),
        I18n.t("no_value"),
        I18n.t("yes_value"),
        function(confirmed) {
          if (confirmed) {
            exportUserArchive();
          }
        }
      );
    }
  }
});
