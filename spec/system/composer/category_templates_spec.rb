# frozen_string_literal: true

describe "Composer Form Templates", type: :system, js: true do
  fab!(:user) { Fabricate(:user) }
  fab!(:form_template_1) do
    Fabricate(:form_template, name: "Bug Reports", template: "- type: checkbox")
  end
  fab!(:form_template_2) do
    Fabricate(:form_template, name: "Feature Request", template: "- type: input")
  end
  fab!(:form_template_3) do
    Fabricate(:form_template, name: "Awesome Possum", template: "- type: dropdown")
  end
  fab!(:form_template_4) do
    Fabricate(:form_template, name: "Biography", template: "- type: textarea")
  end
  fab!(:category_with_template_1) do
    Fabricate(
      :category,
      name: "Reports",
      slug: "reports",
      topic_count: 2,
      form_template_ids: [form_template_1.id],
    )
  end
  fab!(:category_with_template_2) do
    Fabricate(
      :category,
      name: "Features",
      slug: "features",
      topic_count: 3,
      form_template_ids: [form_template_2.id],
    )
  end
  fab!(:category_with_multiple_templates_1) do
    Fabricate(
      :category,
      name: "Multiple",
      slug: "mulitple",
      topic_count: 10,
      form_template_ids: [form_template_1.id, form_template_2.id],
    )
  end
  fab!(:category_with_multiple_templates_2) do
    Fabricate(
      :category,
      name: "More Stuff",
      slug: "more-stuff",
      topic_count: 10,
      form_template_ids: [form_template_3.id, form_template_4.id],
    )
  end
  fab!(:category_no_template) do
    Fabricate(:category, name: "Staff", slug: "staff", topic_count: 2, form_template_ids: [])
  end
  fab!(:category_topic_template) do
    Fabricate(
      :category,
      name: "Random",
      slug: "random",
      topic_count: 5,
      form_template_ids: [],
      topic_template: "Testing",
    )
  end
  let(:category_page) { PageObjects::Pages::Category.new }
  let(:composer) { PageObjects::Components::Composer.new }
  let(:form_template_chooser) { PageObjects::Components::SelectKit.new(".form-template-chooser") }

  before do
    SiteSetting.experimental_form_templates = true
    sign_in user
  end

  it "shows a textarea when no form template is assigned to the category" do
    category_page.visit(category_no_template)
    category_page.new_topic_button.click
    expect(composer).to have_composer_input
  end

  it "shows a textarea filled in with topic template when a topic template is assigned to the category" do
    category_page.visit(category_topic_template)
    category_page.new_topic_button.click
    expect(composer).to have_composer_input
    expect(composer).to have_content(category_topic_template.topic_template)
  end

  it "shows a form when a form template is assigned to the category" do
    category_page.visit(category_with_template_1)
    category_page.new_topic_button.click
    expect(composer).to have_no_composer_input
    expect(composer).to have_form_template
    expect(composer).to have_form_template_field("checkbox")
  end

  it "shows the correct template when switching categories" do
    category_page.visit(category_no_template)
    category_page.new_topic_button.click
    # first category has no template
    expect(composer).to have_composer_input
    # switch to category with topic template
    composer.switch_category(category_topic_template.name)
    expect(composer).to have_composer_input
    expect(composer).to have_content(category_topic_template.topic_template)
    # switch to category with form template
    composer.switch_category(category_with_template_1.name)
    expect(composer).to have_form_template
    expect(composer).to have_form_template_field("checkbox")
    # switch to category with a different form template
    composer.switch_category(category_with_template_2.name)
    expect(composer).to have_form_template
    expect(composer).to have_form_template_field("input")
  end

  it "does not show form template chooser when a category only has form template" do
    category_page.visit(category_with_template_1)
    category_page.new_topic_button.click
    expect(composer).to have_no_form_template_chooser
  end

  it "shows form template chooser when a category has multiple form templates" do
    category_page.visit(category_with_multiple_templates_1)
    category_page.new_topic_button.click
    expect(composer).to have_form_template_chooser
  end

  it "updates the form template when a different template is selected" do
    category_page.visit(category_with_multiple_templates_1)
    category_page.new_topic_button.click
    expect(composer).to have_form_template_field("checkbox")
    form_template_chooser.select_row_by_name(form_template_2.name)
    expect(composer).to have_form_template_field("input")
  end

  it "shows the correct template options when switching categories" do
    category_page.visit(category_with_multiple_templates_1)
    category_page.new_topic_button.click
    expect(composer).to have_form_template_chooser
    form_template_chooser.expand
    expect(form_template_chooser).to have_selected_choice_name(form_template_1.name)
    expect(form_template_chooser).to have_option_name(form_template_2.name)
    composer.switch_category(category_with_multiple_templates_2.name)
    form_template_chooser.expand
    expect(form_template_chooser).to have_selected_choice_name(form_template_3.name)
    expect(form_template_chooser).to have_option_name(form_template_4.name)
  end

  it "shows the correct template name in the dropdown header after switching templates" do
    category_page.visit(category_with_multiple_templates_1)
    category_page.new_topic_button.click
    expect(form_template_chooser).to have_selected_name(form_template_1.name)
    form_template_chooser.select_row_by_name(form_template_2.name)
    expect(form_template_chooser).to have_selected_name(form_template_2.name)
  end
end
