import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array, fn } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { inject as service } from "@ember/service";
import DButton from "discourse/components/d-button";
import BookmarkModal from "discourse/components/modal/bookmark";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
import {
  TIME_SHORTCUT_TYPES,
  timeShortcuts,
} from "discourse/lib/time-shortcut";
import icon from "discourse-common/helpers/d-icon";
import i18n from "discourse-common/helpers/i18n";
import I18n from "discourse-i18n";
import DMenu from "float-kit/components/d-menu";

export default class BookmarkMenu extends Component {
  @service modal;
  @service currentUser;
  @service toasts;
  @tracked quicksaved = false;

  bookmarkManager = this.args.bookmarkManager;
  timezone = this.currentUser?.user_option?.timezone || moment.tz.guess();
  timeShortcuts = timeShortcuts(this.timezone);

  @action
  setReminderShortcuts() {
    this.reminderAtOptions = [
      this.timeShortcuts.twoHours(),
      this.timeShortcuts.tomorrow(),
      this.timeShortcuts.threeDays(),
    ];

    // So the label is a simple 'Custom...'
    const custom = this.timeShortcuts.custom();
    custom.label = "time_shortcut.custom_short";
    this.reminderAtOptions.push(custom);
  }

  get existingBookmark() {
    return this.bookmarkManager.trackedBookmark.id
      ? this.bookmarkManager.trackedBookmark
      : null;
  }

  get showEditDeleteMenu() {
    return this.existingBookmark && !this.quicksaved;
  }

  get buttonTitle() {
    if (!this.existingBookmark) {
      return I18n.t("bookmarks.not_bookmarked");
    } else {
      if (this.existingBookmark.reminderAt) {
        return I18n.t("bookmarks.created_with_reminder", {
          date: this.existingBookmark.formattedReminder(this.timezone),
          name: this.existingBookmark.name || "",
        });
      } else {
        return I18n.t("bookmarks.created", {
          name: this.existingBookmark.name || "",
        });
      }
    }
  }

  @action
  reminderShortcutTimeTitle(option) {
    if (!option.time) {
      return "";
    }
    return option.time.format(I18n.t(option.timeFormatKey));
  }

  @action
  async onBookmark() {
    try {
      await this.bookmarkManager.create();
      // We show the menu with Edit/Delete options if the bokmark exists,
      // so this "quicksave" will do nothing in that case.
      // NOTE: Need a nicer way to handle this; otherwise as soon as you save
      // a bookmark, it switches to the other Edit/Delete menu.
      this.quicksaved = true;
      this.toasts.success({
        duration: 3000,
        data: { message: I18n.t("bookmarks.bookmarked_success") },
      });
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  onShowMenu() {
    if (!this.existingBookmark) {
      this.onBookmark();
    }
  }

  @action
  onRegisterApi(api) {
    this.dMenu = api;
  }

  @action
  onEditBookmark() {
    this._openBookmarkModal();
  }

  @action
  onCloseMenu() {
    this.quicksaved = false;
  }

  @action
  async onRemoveBookmark() {
    try {
      const response = await this.bookmarkManager.delete();
      this.bookmarkManager.afterDelete(response, this.existingBookmark.id);
      this.toasts.success({
        duration: 3000,
        data: { message: I18n.t("bookmarks.deleted_bookmark_success") },
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.dMenu.close();
    }
  }

  @action
  async onChooseReminderOption(option) {
    if (option.id === TIME_SHORTCUT_TYPES.CUSTOM) {
      this._openBookmarkModal();
    } else {
      this.existingBookmark.selectedReminderType = option.id;
      this.existingBookmark.selectedDatetime = option.time;
      this.existingBookmark.reminderAt = option.time;

      try {
        await this.bookmarkManager.save();
        this.toasts.success({
          duration: 3000,
          data: { message: I18n.t("bookmarks.reminder_set_success") },
        });
      } catch (error) {
        popupAjaxError(error);
      } finally {
        this.dMenu.close();
      }
    }
  }

  async _openBookmarkModal() {
    try {
      const closeData = await this.modal.show(BookmarkModal, {
        model: {
          bookmark: this.existingBookmark,
          afterSave: (savedData) => {
            return this.bookmarkManager.afterSave(savedData);
          },
          afterDelete: (response, bookmarkId) => {
            this.bookmarkManager.afterDelete(response, bookmarkId);
          },
        },
      });
      this.bookmarkManager.afterModalClose(closeData);
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <DMenu
      {{didInsert this.setReminderShortcuts}}
      @identifier="bookmark-menu"
      @triggers={{array "click"}}
      @arrow="true"
      class={{concatClass
        "bookmark widget-button btn-flat no-text btn-icon bookmark-menu__trigger"
        (if this.existingBookmark "bookmarked")
        (if this.existingBookmark.reminderAt "with-reminder")
      }}
      @title={{this.buttonTitle}}
      @onClose={{this.onCloseMenu}}
      @onShow={{this.onShowMenu}}
      @onRegisterApi={{this.onRegisterApi}}
    >
      <:trigger>
        {{#if this.existingBookmark.reminderAt}}
          {{icon "discourse-bookmark-clock"}}
        {{else}}
          {{icon "bookmark"}}
        {{/if}}
      </:trigger>
      <:content>
        <div class="bookmark-menu__body">
          {{#if this.showEditDeleteMenu}}
            <ul class="bookmark-menu__actions">
              <li class="bookmark-menu__row -edit" data-menu-option-id="edit">
                <DButton
                  @icon="pencil-alt"
                  @label="edit"
                  @action={{this.onEditBookmark}}
                  @class="bookmark-menu__row-btn btn-flat"
                />
              </li>
              <li
                class="bookmark-menu__row -remove"
                role="button"
                tabindex="0"
                data-menu-option-id="delete"
              >
                <DButton
                  @icon="trash-alt"
                  @label="delete"
                  @action={{this.onRemoveBookmark}}
                  @class="bookmark-menu__row-btn btn-flat"
                />
              </li>
            </ul>
          {{else}}
            <span class="bookmark-menu__row-title">{{i18n
                "bookmarks.also_set_reminder"
              }}</span>
            <ul class="bookmark-menu__actions">
              {{#each this.reminderAtOptions as |option|}}
                <li
                  class="bookmark-menu__row"
                  data-menu-option-id={{option.id}}
                >
                  <DButton
                    @label={{option.label}}
                    @translatedTitle={{this.reminderShortcutTimeTitle option}}
                    @action={{fn this.onChooseReminderOption option}}
                    @class="bookmark-menu__row-btn btn-flat"
                  />
                </li>
              {{/each}}
            </ul>
          {{/if}}
        </div>
      </:content>
    </DMenu>
  </template>
}
