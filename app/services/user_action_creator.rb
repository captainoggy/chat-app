class UserActionCreator
  def self.disable
    @disabled = true
  end

  def self.enable
    @disabled = false
  end

  def self.log_notification(post, user, notification_type, acting_user_id = nil)
    return if @disabled

    action =
      case notification_type
      when Notification.types[:quoted]
        UserAction::QUOTE
      when Notification.types[:replied]
        UserAction::RESPONSE
      when Notification.types[:mentioned]
        UserAction::MENTION
      when Notification.types[:edited]
        UserAction::EDIT
      end

    # skip any invalid items, eg failed to save post and so on
    return unless action && post && user && post.id

    row = {
      action_type: action,
      user_id: user.id,
      acting_user_id: acting_user_id || post.user_id,
      target_topic_id: post.topic_id,
      target_post_id: post.id
    }

    if post.deleted_at.nil?
      UserAction.log_action!(row)
    else
      UserAction.remove_action!(row)
    end
  end

  def self.log_post(model)
    return if @disabled

    # first post gets nada
    return if model.is_first_post?
    return if model.topic.blank?

    row = {
      action_type: UserAction::REPLY,
      user_id: model.user_id,
      acting_user_id: model.user_id,
      target_post_id: model.id,
      target_topic_id: model.topic_id,
      created_at: model.created_at
    }

    rows = [row]

    if model.topic.private_message?
      rows = []
      model.topic.topic_allowed_users.each do |ta|
        row = row.dup
        row[:user_id] = ta.user_id
        row[:action_type] = ta.user_id == model.user_id ? UserAction::NEW_PRIVATE_MESSAGE : UserAction::GOT_PRIVATE_MESSAGE
        rows << row
      end
    end

    rows.each do |r|
      if model.deleted_at.nil?
        UserAction.log_action!(r)
      else
        UserAction.remove_action!(r)
      end
    end
  end

  def self.log_topic(model)
    return if @disabled

    # no action to log here, this can happen if a user is deleted
    # then topic has no user_id
    return unless model.user_id

    row = {
      action_type: model.archetype == Archetype.private_message ? UserAction::NEW_PRIVATE_MESSAGE : UserAction::NEW_TOPIC,
      user_id: model.user_id,
      acting_user_id: model.user_id,
      target_topic_id: model.id,
      target_post_id: -1,
      created_at: model.created_at
    }

    UserAction.remove_action!(row.merge(
      action_type: model.archetype == Archetype.private_message ? UserAction::NEW_TOPIC : UserAction::NEW_PRIVATE_MESSAGE
    ))

    rows = [row]

    if model.private_message?
      model.topic_allowed_users.reject { |a| a.user_id == model.user_id }.each do |ta|
        row = row.dup
        row[:user_id] = ta.user_id
        row[:action_type] = UserAction::GOT_PRIVATE_MESSAGE
        rows << row
      end
    end

    rows.each do |r|
      if model.deleted_at.nil?
        UserAction.log_action!(r)
      else
        UserAction.remove_action!(r)
      end
    end
  end

  def self.log_post_action(model)
    return if @disabled

    action = UserAction::BOOKMARK if model.is_bookmark?
    action = UserAction::LIKE if model.is_like?

    post = Post.with_deleted.where(id: model.post_id).first

    row = {
      action_type: action,
      user_id: model.user_id,
      acting_user_id: model.user_id,
      target_post_id: model.post_id,
      target_topic_id: post.topic_id,
      created_at: model.created_at
    }

    if model.deleted_at.nil?
      UserAction.log_action!(row)
    else
      UserAction.remove_action!(row)
    end

    if model.is_like?
      row[:action_type] = UserAction::WAS_LIKED
      row[:user_id] = post.user_id
      if model.deleted_at.nil?
        UserAction.log_action!(row)
      else
        UserAction.remove_action!(row)
      end
    end
  end
end
