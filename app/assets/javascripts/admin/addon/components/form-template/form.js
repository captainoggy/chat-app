import Component from "@glimmer/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import I18n from "I18n";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { templateFormFields } from "admin/lib/template-form-fields";
import FormTemplate from "admin/models/form-template";
import showModal from "discourse/lib/show-modal";

export default class FormTemplateForm extends Component {
  @service router;
  @service dialog;
  @tracked formSubmitted = false;
  @tracked templateContent = this.args.model?.template || "";
  @tracked templateName = this.args.model?.name || "";
  isEditing = this.args.model?.id ? true : false;
  quickInsertFields = [
    {
      type: "checkbox",
      icon: "check-square",
    },
    {
      type: "input",
      icon: "grip-lines",
    },
    {
      type: "textarea",
      icon: "align-left",
    },
    {
      type: "dropdown",
      icon: "chevron-circle-down",
    },
    // TODO(@keegan): add support for uploads
    // {
    //   type: "upload",
    //   icon: "cloud-upload-alt",
    // },
    {
      type: "multiselect",
      icon: "bullseye",
    },
  ];

  get disablePreviewButton() {
    return Boolean(!this.templateName.length || !this.templateContent.length);
  }

  get disableSubmitButton() {
    return (
      Boolean(!this.templateName.length || !this.templateContent.length) ||
      this.formSubmitted
    );
  }

  @action
  onSubmit() {
    if (!this.formSubmitted) {
      this.formSubmitted = true;
    }

    const postData = {
      name: this.templateName,
      template: this.templateContent,
    };

    if (this.isEditing) {
      postData["id"] = this.args.model.id;
    }

    FormTemplate.createOrUpdateTemplate(postData)
      .then(() => {
        this.formSubmitted = false;
        this.router.transitionTo("adminCustomizeFormTemplates.index");
      })
      .catch((e) => {
        popupAjaxError(e);
        this.formSubmitted = false;
      });
  }

  @action
  onCancel() {
    this.router.transitionTo("adminCustomizeFormTemplates.index");
  }

  @action
  onDelete() {
    return this.dialog.yesNoConfirm({
      message: I18n.t("admin.form_templates.delete_confirm"),
      didConfirm: () => {
        FormTemplate.deleteTemplate(this.args.model.id)
          .then(() => {
            this.router.transitionTo("adminCustomizeFormTemplates.index");
          })
          .catch(popupAjaxError);
      },
    });
  }

  @action
  onInsertField(type) {
    const structure = templateFormFields.findBy("type", type).structure;

    if (this.templateContent.length === 0) {
      this.templateContent += structure;
    } else {
      this.templateContent += `\n${structure}`;
    }
  }

  @action
  showValidationOptionsModal() {
    return showModal("admin-form-template-validation-options", {
      admin: true,
    });
  }

  @action
  showPreview() {
    const data = {
      name: this.templateName,
      template: this.templateContent,
    };

    if (this.isEditing) {
      data["id"] = this.args.model.id;
    }

    FormTemplate.validateTemplate(data)
      .then(() => {
        return showModal("form-template-form-preview", {
          model: {
            content: this.templateContent,
          },
        });
      })
      .catch(popupAjaxError);
  }
}
