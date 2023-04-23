import { escapeExpression } from "discourse/lib/utilities";
import { ajax } from "discourse/lib/ajax";
import { cancel } from "@ember/runloop";
import discourseDebounce from "discourse-common/lib/debounce";
import Controller from "@ember/controller";
import I18n from "I18n";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { action, computed } from "@ember/object";
import { gt, notEmpty } from "@ember/object/computed";
import { inject as service } from "@ember/service";
import { isBlank, isPresent } from "@ember/utils";
import { htmlSafe } from "@ember/template";

const DEFAULT_HINT = htmlSafe(
  I18n.t("chat.create_channel.choose_category.default_hint", {
    link: "/categories",
    category: "category",
  })
);

export default class CreateChannelController extends Controller.extend(
  ModalFunctionality
) {
  @service chat;
  @service dialog;
  @service chatChannelsManager;
  @service chatApi;
  @service router;

  category = null;
  categoryId = null;
  name = "";
  slug = "";
  autoGeneratedSlug = "";
  description = "";
  categoryPermissionsHint = null;
  autoJoinUsers = false;
  autoJoinWarning = "";
  loadingPermissionHint = false;

  @notEmpty("category") categorySelected;
  @gt("siteSettings.max_chat_auto_joined_users", 0) autoJoinAvailable;

  @computed("categorySelected", "name")
  get createDisabled() {
    return !this.categorySelected || isBlank(this.name);
  }

  @computed("categorySelected", "name")
  get categoryName() {
    return this.categorySelected && isPresent(this.name)
      ? escapeExpression(this.name)
      : null;
  }

  onShow() {
    this.set("categoryPermissionsHint", DEFAULT_HINT);
  }

  onClose() {
    cancel(this.generateSlugHandler);
    this.setProperties({
      categoryId: null,
      category: null,
      name: "",
      description: "",
      slug: "",
      autoGeneratedSlug: "",
      categoryPermissionsHint: DEFAULT_HINT,
      autoJoinWarning: "",
    });
  }

  _createChannel() {
    const data = {
      chatable_id: this.categoryId,
      name: this.name,
      slug: this.slug || this.autoGeneratedSlug,
      description: this.description,
      auto_join_users: this.autoJoinUsers,
    };

    return this.chatApi
      .createChannel(data)
      .then((channel) => {
        this.send("closeModal");
        this.chatChannelsManager.follow(channel);
        this.router.transitionTo("chat.channel", ...channel.routeModels);
      })
      .catch((e) => {
        this.flash(e.jqXHR.responseJSON.errors[0], "error");
      });
  }

  _buildCategorySlug(category) {
    const parent = category.parentCategory;

    if (parent) {
      return `${this._buildCategorySlug(parent)}/${category.slug}`;
    } else {
      return category.slug;
    }
  }

  _updateAutoJoinConfirmWarning(category, catPermissions) {
    const allowedGroups = catPermissions.allowed_groups;
    let warning;

    if (catPermissions.private) {
      switch (allowedGroups.length) {
        case 1:
          warning = I18n.t(
            "chat.create_channel.auto_join_users.warning_1_group",
            {
              count: catPermissions.members_count,
              group: escapeExpression(allowedGroups[0]),
            }
          );
          break;
        case 2:
          warning = I18n.t(
            "chat.create_channel.auto_join_users.warning_2_groups",
            {
              count: catPermissions.members_count,
              group1: escapeExpression(allowedGroups[0]),
              group2: escapeExpression(allowedGroups[1]),
            }
          );
          break;
        default:
          warning = I18n.messageFormat(
            "chat.create_channel.auto_join_users.warning_multiple_groups_MF",
            {
              groupCount: allowedGroups.length - 1,
              userCount: catPermissions.members_count,
              groupName: escapeExpression(allowedGroups[0]),
            }
          );
          break;
      }
    } else {
      warning = I18n.t(
        "chat.create_channel.auto_join_users.public_category_warning",
        {
          category: escapeExpression(category.name),
        }
      );
    }

    this.set("autoJoinWarning", warning);
  }

  _updatePermissionsHint(category) {
    if (category) {
      const fullSlug = this._buildCategorySlug(category);

      this.set("loadingPermissionHint", true);

      return this.chatApi
        .categoryPermissions(category.id)
        .then((catPermissions) => {
          this._updateAutoJoinConfirmWarning(category, catPermissions);
          const allowedGroups = catPermissions.allowed_groups;
          const settingLink = `/c/${escapeExpression(fullSlug)}/edit/security`;
          let hint;

          switch (allowedGroups.length) {
            case 1:
              hint = I18n.t(
                "chat.create_channel.choose_category.hint_1_group",
                {
                  settingLink,
                  group: escapeExpression(allowedGroups[0]),
                }
              );
              break;
            case 2:
              hint = I18n.t(
                "chat.create_channel.choose_category.hint_2_groups",
                {
                  settingLink,
                  group1: escapeExpression(allowedGroups[0]),
                  group2: escapeExpression(allowedGroups[1]),
                }
              );
              break;
            default:
              hint = I18n.t(
                "chat.create_channel.choose_category.hint_multiple_groups",
                {
                  settingLink,
                  group: escapeExpression(allowedGroups[0]),
                  count: allowedGroups.length - 1,
                }
              );
              break;
          }

          this.set("categoryPermissionsHint", htmlSafe(hint));
        })
        .finally(() => {
          this.set("loadingPermissionHint", false);
        });
    } else {
      this.set("categoryPermissionsHint", DEFAULT_HINT);
      this.set("autoJoinWarning", "");
    }
  }

  // intentionally not showing AJAX error for this, we will autogenerate
  // the slug server-side if they leave it blank
  _generateSlug(name) {
    ajax("/slugs.json", { type: "POST", data: { name } }).then((response) => {
      this.set("autoGeneratedSlug", response.slug);
    });
  }

  _debouncedGenerateSlug(name) {
    cancel(this.generateSlugHandler);
    this._clearAutoGeneratedSlug();
    if (!name) {
      return;
    }
    this.generateSlugHandler = discourseDebounce(
      this,
      this._generateSlug,
      name,
      300
    );
  }

  _clearAutoGeneratedSlug() {
    this.set("autoGeneratedSlug", "");
  }

  @action
  onCategoryChange(categoryId) {
    let category = categoryId
      ? this.site.categories.findBy("id", categoryId)
      : null;
    this._updatePermissionsHint(category);

    const name = this.name || category?.name || "";
    this.setProperties({
      categoryId,
      category,
      name,
    });
    this._debouncedGenerateSlug(name);
  }

  @action
  onNameChange(name) {
    this._debouncedGenerateSlug(name);
  }

  @action
  create() {
    if (this.createDisabled) {
      return;
    }

    if (this.autoJoinUsers) {
      this.dialog.yesNoConfirm({
        message: this.autoJoinWarning,
        didConfirm: () => this._createChannel(),
      });
    } else {
      this._createChannel();
    }
  }
}
