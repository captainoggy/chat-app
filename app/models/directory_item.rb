class DirectoryItem < ActiveRecord::Base
  belongs_to :user
  has_one :user_stat, foreign_key: :user_id, primary_key: :user_id

  def self.headings
    @headings ||= [:likes_received,
                   :likes_given,
                   :topics_entered,
                   :topic_count,
                   :post_count]
  end

  def self.period_types
    @types ||= Enum.new(:all, :yearly, :monthly, :weekly, :daily)
  end

  def self.refresh!
    ActiveRecord::Base.transaction do
      exec_sql "TRUNCATE TABLE directory_items"
      period_types.keys.each {|p| refresh_period!(p)}
    end
  end

  def self.refresh_period!(period_type)
    since = case period_type
            when :daily then 1.day.ago
            when :weekly then 1.week.ago
            when :monthly then 1.month.ago
            when :yearly then 1.year.ago
            else 1000.years.ago
            end

    exec_sql "INSERT INTO directory_items
                (period_type, user_id, likes_received, likes_given, topics_entered, topic_count, post_count)
                SELECT
                  :period_type,
                  u.id,
                  SUM(CASE WHEN ua.action_type = :was_liked_type THEN 1 ELSE 0 END),
                  SUM(CASE WHEN ua.action_type = :like_type THEN 1 ELSE 0 END),
                  (SELECT COUNT(topic_id) FROM topic_views AS v WHERE v.user_id = u.id AND v.viewed_at > :since),
                  SUM(CASE WHEN ua.action_type = :new_topic_type THEN 1 ELSE 0 END),
                  SUM(CASE WHEN ua.action_type = :reply_type THEN 1 ELSE 0 END)
                FROM users AS u
                LEFT OUTER JOIN user_actions AS ua ON ua.user_id = u.id
                LEFT OUTER JOIN topics AS t ON ua.target_topic_id = t.id
                LEFT OUTER JOIN posts AS p ON ua.target_post_id = p.id
                LEFT OUTER JOIN categories AS c ON t.category_id = c.id
                WHERE u.active
                  AND NOT u.blocked
                  AND COALESCE(ua.created_at, :since) >= :since
                  AND t.deleted_at IS NULL
                  AND COALESCE(t.visible, true)
                  AND COALESCE(t.archetype, 'regular') = 'regular'
                  AND p.deleted_at IS NULL
                  AND NOT (COALESCE(p.hidden, false))
                  AND NOT COALESCE(c.read_restricted, false)
                  AND p.post_type != :moderator_action
                  AND u.id > 0
                GROUP BY u.id",
                period_type: period_types[period_type],
                since: since,
                like_type: UserAction::LIKE,
                was_liked_type: UserAction::WAS_LIKED,
                new_topic_type: UserAction::NEW_TOPIC,
                reply_type: UserAction::REPLY,
                moderator_action: Post.types[:moderator_action]
  end
end
