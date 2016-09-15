class Wizard
  class Builder

    def initialize(user)
      @wizard = Wizard.new(user)
    end

    def build
      return @wizard unless SiteSetting.wizard_enabled? && @wizard.user.try(:staff?)

      @wizard.append_step('locale') do |step|
        languages = step.add_field(id: 'default_locale',
                                   type: 'dropdown',
                                   required: true,
                                   value: SiteSetting.default_locale)

        LocaleSiteSetting.values.each do |locale|
          languages.add_choice(locale[:value], label: locale[:name])
        end

        step.on_update do |updater|
          old_locale = SiteSetting.default_locale
          updater.apply_setting(:default_locale)
          updater.refresh_required = true if old_locale != updater.fields[:default_locale]
        end
      end

      @wizard.append_step('forum-title') do |step|
        step.add_field(id: 'title', type: 'text', required: true, value: SiteSetting.title)
        step.add_field(id: 'site_description', type: 'text', required: true, value: SiteSetting.site_description)

        step.on_update do |updater|
          updater.ensure_changed(:title)

          if updater.errors.blank?
            updater.apply_settings(:title, :site_description)
          end
        end
      end

      @wizard.append_step('privacy') do |step|
        locked = SiteSetting.login_required? && SiteSetting.invite_only?
        privacy = step.add_field(id: 'privacy',
                                 type: 'radio',
                                 required: true,
                                 value: locked ? 'restricted' : 'open')
        privacy.add_choice('open', icon: 'unlock')
        privacy.add_choice('restricted', icon: 'lock')

        step.on_update do |updater|
          updater.update_setting(:login_required, updater.fields[:privacy] == 'restricted')
          updater.update_setting(:invite_only, updater.fields[:privacy] == 'restricted')
        end
      end

      @wizard.append_step('contact') do |step|
        step.add_field(id: 'contact_email', type: 'text', required: true, value: SiteSetting.contact_email)
        step.add_field(id: 'contact_url', type: 'text', value: SiteSetting.contact_url)

        username = SiteSetting.site_contact_username
        username = Discourse.system_user.username if username.blank?
        contact = step.add_field(id: 'site_contact', type: 'dropdown', value: username)

        User.where(admin: true).pluck(:username).each {|c| contact.add_choice(c) }

        step.on_update do |updater|
          updater.apply_settings(:contact_email, :contact_url)
          updater.update_setting(:site_contact_username, updater.fields[:site_contact])
        end
      end

      @wizard.append_step('corporate') do |step|
        step.add_field(id: 'company_short_name', type: 'text', value: SiteSetting.company_short_name)
        step.add_field(id: 'company_full_name', type: 'text', value: SiteSetting.company_full_name)
        step.add_field(id: 'company_domain', type: 'text', value: SiteSetting.company_domain)

        step.on_update do |updater|

          tos_post = Post.where(topic_id: SiteSetting.tos_topic_id, post_number: 1).first
          if tos_post.present?
            raw = tos_post.raw.dup

            replace_company(updater, raw, 'company_full_name')
            replace_company(updater, raw, 'company_short_name')
            replace_company(updater, raw, 'company_domain')

            revisor = PostRevisor.new(tos_post)
            revisor.revise!(@wizard.user, raw: raw)
          end

          updater.apply_settings(:company_short_name, :company_full_name, :company_domain)
        end
      end

      @wizard.append_step('colors') do |step|
        theme_id = ColorScheme.where(via_wizard: true).pluck(:theme_id)
        theme_id = theme_id.present? ? theme_id[0] : 'default'

        themes = step.add_field(id: 'theme_id', type: 'dropdown', required: true, value: theme_id)
        ColorScheme.themes.each {|t| themes.add_choice(t[:id], data: t) }
        step.add_field(id: 'theme_preview', type: 'component')

        step.on_update do |updater|
          scheme_name = updater.fields[:theme_id]

          theme = ColorScheme.themes.find {|s| s[:id] == scheme_name }

          colors = []
          theme[:colors].each do |name, hex|
            colors << {name: name, hex: hex[1..-1] }
          end

          attrs = {
            enabled: true,
            name: I18n.t("wizard.step.colors.fields.color_scheme.options.#{scheme_name}"),
            colors: colors,
            theme_id: scheme_name
          }

          scheme = ColorScheme.where(via_wizard: true).first
          if scheme.present?
            attrs[:colors] = colors
            revisor = ColorSchemeRevisor.new(scheme, attrs)
            revisor.revise
          else
            attrs[:via_wizard] = true
            scheme = ColorScheme.new(attrs)
            scheme.save!
          end
        end
      end

      @wizard.append_step('logos') do |step|
        step.add_field(id: 'logo_url', type: 'image', value: SiteSetting.logo_url)
        step.add_field(id: 'logo_small_url', type: 'image', value: SiteSetting.logo_small_url)
        step.add_field(id: 'favicon_url', type: 'image', value: SiteSetting.favicon_url)
        step.add_field(id: 'apple_touch_icon_url', type: 'image', value: SiteSetting.apple_touch_icon_url)

        step.on_update do |updater|
          updater.apply_settings(:logo_url, :logo_small_url, :favicon_url, :apple_touch_icon_url)
        end
      end

      @wizard.append_step('invites') do |step|
        step.add_field(id: 'invite_list', type: 'component')

        step.on_update do |updater|
          users = JSON.parse(updater.fields[:invite_list])

          users.each do |u|
            Invite.create_invite_by_email(u['email'], @wizard.user)
          end
        end
      end

      DiscourseEvent.trigger(:build_wizard, @wizard)

      @wizard.append_step('finished')
      @wizard
    end

  protected

    def replace_company(updater, raw, field_name)
      old_value = SiteSetting.send(field_name)
      old_value = field_name if old_value.blank?

      new_value = updater.fields[field_name.to_sym]
      new_value = field_name if new_value.blank?

      raw.gsub!(old_value, new_value)
    end
  end
end

