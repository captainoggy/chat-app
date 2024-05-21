# frozen_string_literal: true

class PostActionType < ActiveRecord::Base
  after_save :expire_cache
  after_destroy :expire_cache

  include AnonCacheInvalidator

  def expire_cache
    ApplicationSerializer.expire_cache_fragment!(/\Apost_action_types_/)
    ApplicationSerializer.expire_cache_fragment!(/\Apost_action_flag_types_/)
  end

  class << self
    attr_reader :flag_settings

    def replace_flag_settings(settings)
      if settings
        @flag_settings = settings
      else
        reload_types
      end
      @types = nil
    end

    def ordered
      order("position asc")
    end

    def types
      unless @types
        # NOTE: Previously bookmark was type 1 but that has been superseded
        # by the separate Bookmark model and functionality
        @types = Enum.new(like: 2)
        @types.merge!(flag_settings.flag_types)
      end

      @types
    end

    def auto_action_flag_types
      flag_settings.auto_action_types
    end

    def public_types
      @public_types ||= types.except(*flag_types.keys << :notify_user)
    end

    def public_type_ids
      @public_type_ids ||= public_types.values
    end

    def flag_types_without_custom
      flag_settings.without_custom_types
    end

    def flag_types
      flag_settings.flag_types
    end

    # flags resulting in mod notifications
    def notify_flag_type_ids
      notify_flag_types.values
    end

    def notify_flag_types
      flag_settings.notify_types
    end

    def topic_flag_types
      flag_settings.topic_flag_types
    end

    def custom_types
      flag_settings.custom_types
    end

    def is_flag?(sym)
      flag_types.valid?(sym)
    end

    def reload_types
      @types = nil
      @flag_settings = FlagSettings.new
      Flag
        .enabled
        .order(:position)
        .each do |flag|
          @flag_settings.add(
            flag.id,
            flag.name_key.to_sym,
            topic_type: flag.applies_to?("Topic"),
            notify_type: flag.notify_type,
            auto_action_type: flag.auto_action_type,
            custom_type: flag.custom_type,
            name: flag.name,
          )
        end
    end
  end

  reload_types
end

# == Schema Information
#
# Table name: post_action_types
#
#  name_key            :string(50)       not null
#  is_flag             :boolean          default(FALSE), not null
#  icon                :string(20)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  id                  :integer          not null, primary key
#  position            :integer          default(0), not null
#  score_bonus         :float            default(0.0), not null
#  reviewable_priority :integer          default(0), not null
#
