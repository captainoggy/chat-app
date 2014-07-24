User.reset_column_information
Topic.reset_column_information
Post.reset_column_information

staff = Category.find_by(id: SiteSetting.staff_category_id)

if Topic.where('id NOT IN (SELECT topic_id from categories where topic_id is not null)').count == 0 && !Rails.env.test?
  puts "Seeding welcome topics"

  welcome = File.read(Rails.root + 'docs/ADMIN-QUICK-START-GUIDE.md')
  PostCreator.create(Discourse.system_user, raw: welcome, title: "READ ME FIRST: Admin Quick Start Guide", skip_validations: true, category: staff ? staff.name : nil)
  PostCreator.create(Discourse.system_user, raw: I18n.t('assets_topic_body'), title: "Assets for the forum design", skip_validations: true, category: staff ? staff.name : nil)

  welcome = File.read(Rails.root + 'docs/WELCOME-TO-DISCOURSE.md')
  post = PostCreator.create(Discourse.system_user, raw: welcome, title: "Welcome to Discourse", skip_validations: true)
  post.topic.update_pinned(true, true)

  lounge = Category.find_by(id: SiteSetting.lounge_category_id)
  if lounge
    post = PostCreator.create(Discourse.system_user, raw: I18n.t('lounge_welcome.body'), title: I18n.t('lounge_welcome.title'), skip_validations: true, category: lounge.name)
    post.topic.update_pinned(true)
  end
end

unless Rails.env.test?
  def create_static_page_topic(site_setting_key, title_key, body_key, body_override, category, description, params={})
    unless SiteSetting.send(site_setting_key) > 0
      post = PostCreator.create( Discourse.system_user,
                                 title: I18n.t(title_key, default: I18n.t(title_key, locale: :en)),
                                 raw: body_override.present? ? body_override : I18n.t(body_key, params.merge(default: I18n.t(body_key, params.merge(locale: :en)))),
                                 skip_validations: true,
                                 category: category ? category.name : nil)

      raise "Failed to create the #{description} topic! #{post.errors.full_messages.join('. ')}" unless post.valid?

      SiteSetting.send("#{site_setting_key}=", post.topic_id)

      reply = PostCreator.create( Discourse.system_user,
                                  raw: I18n.t('static_topic_first_reply', page_name: I18n.t(title_key, default: I18n.t(title_key, locale: :en))),
                                  skip_validations: true,
                                  topic_id: post.topic_id )
    end
  end

  create_static_page_topic('tos_topic_id', 'tos_topic.title', "tos_topic.body", nil, staff, "terms of service", {
    company_domain: SiteSetting.company_domain,
    company_full_name: SiteSetting.company_full_name,
    company_name: SiteSetting.company_short_name
  })

  create_static_page_topic('guidelines_topic_id', 'guidelines_topic.title', "guidelines_topic.body",
                           (SiteContent.content_for(:faq) rescue nil), staff, "guidelines")

  create_static_page_topic('privacy_topic_id', 'privacy_topic.title', "privacy_topic.body",
                           (SiteContent.content_for(:privacy_policy) rescue nil), staff, "privacy policy")
end
