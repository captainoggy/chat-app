# frozen_string_literal: true

module PageObjects
  module Modals
    class SidebarEditCategories < PageObjects::Modals::Base
      def closed?
        has_no_css?(".sidebar-categories-form-modal")
      end

      def has_right_title?(title)
        has_css?(".sidebar-categories-form-modal #discourse-modal-title", text: title)
      end

      def has_parent_category_color?(category)
        has_css?(
          ".sidebar-categories-form-modal .sidebar-categories-form__row",
          style: "border-left-color: ##{category.color} ",
        )
      end

      def has_category_description_excerpt?(category)
        has_css?(
          ".sidebar-categories-form-modal .sidebar-categories-form__category-row",
          text: category.description_excerpt,
        )
      end

      def has_no_categories?
        has_no_css?(".sidebar-categories-form-modal .sidebar-categories-form__category-row") &&
          has_css?(
            ".sidebar-categories-form-modal .sidebar-categories-form__no-categories",
            text: I18n.t("js.sidebar.categories_form_modal.no_categories"),
          )
      end

      def has_categories?(categories)
        category_ids = categories.map(&:id)

        has_css?(
          ".sidebar-categories-form-modal .sidebar-categories-form__category-row",
          count: category_ids.length,
        ) &&
          all(".sidebar-categories-form-modal .sidebar-categories-form__category-row").all? do |row|
            category_ids.include?(row["data-category-id"].to_i)
          end
      end

      def toggle_category_checkbox(category)
        find(
          ".sidebar-categories-form-modal .sidebar-categories-form__category-row[data-category-id='#{category.id}'] .sidebar-categories-form__input",
        ).click

        self
      end

      def save
        find(".sidebar-categories-form-modal .sidebar-categories-form__save-button").click
        self
      end

      def filter(text)
        find(".sidebar-categories-form-modal .sidebar-categories-form__filter-input-field").fill_in(
          with: text,
        )

        self
      end

      def deselect_all
        click_button(I18n.t("js.sidebar.categories_form_modal.subtitle.button_text"))
        self
      end

      def click_reset_to_defaults_button
        click_button(I18n.t("js.sidebar.categories_form_modal.reset_to_defaults"))
        self
      end

      def has_no_reset_to_defaults_button?
        has_no_button?(I18n.t("js.sidebar.categories_form_modal.reset_to_defaults"))
      end

      def has_focus_on_filter_input?
        evaluate_script("document.activeElement").native ==
          find(".sidebar-categories-form-modal .sidebar-categories-form__filter-input-field").native
      end
    end
  end
end
