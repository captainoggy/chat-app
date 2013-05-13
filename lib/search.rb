module Search

  def self.per_facet
    5
  end

  def self.facets
    %w(topic category user)
  end

  def self.user_query_sql
    "SELECT 'user' AS type,
                  u.username_lower AS id,
                  '/users/' || u.username_lower AS url,
                  u.username AS title,
                  u.email,
                  NULL AS color,
                  NULL AS text_color
    FROM users AS u
    JOIN users_search s on s.id = u.id
    WHERE s.search_data @@ TO_TSQUERY(:locale, :query)
    ORDER BY CASE WHEN u.username_lower = lower(:orig) then 0 else 1 end,  last_posted_at desc
    LIMIT :limit
    "
  end

  def self.post_query(current_user, type, args)
    builder = SqlBuilder.new <<SQL
    /*select*/
    FROM topics AS ft
    /*join*/
      JOIN posts_search s on s.id = p.id
      LEFT JOIN categories c ON c.id = ft.category_id
    /*where*/
    ORDER BY
            TS_RANK_CD(TO_TSVECTOR(:locale, ft.title), TO_TSQUERY(:locale, :query)) desc,
            TS_RANK_CD(search_data, TO_TSQUERY(:locale, :query)) desc,
            bumped_at desc
    LIMIT :limit
SQL

    builder.select "'topic' AS type"
    builder.select("CAST(ft.id AS VARCHAR)")

    if type == :topic
      builder.select "'/t/slug/' || ft.id AS url"
    else
      builder.select "'/t/slug/' || ft.id || '/' || p.post_number AS url"
    end

    builder.select "ft.title, NULL AS email, NULL AS color, NULL AS text_color"

  if type == :topic
    builder.join "posts AS p ON p.topic_id = ft.id AND p.post_number = 1"
  else
    builder.join "posts AS p ON p.topic_id = ft.id AND p.post_number > 1"
  end

    builder.where <<SQL
s.search_data @@ TO_TSQUERY(:locale, :query)
      AND ft.deleted_at IS NULL
      AND p.deleted_at IS NULL
      AND ft.visible
      AND ft.archetype <> '#{Archetype.private_message}'
SQL

    allowed_categories = nil
    allowed_categories = current_user.secure_category_ids if current_user
    if allowed_categories.present?
      builder.where("(c.id IS NULL OR c.secure = 'f' OR c.id in (:category_ids))", category_ids: allowed_categories)
    else
      builder.where("(c.id IS NULL OR c.secure = 'f')")
    end

    builder.exec(args)
  end


  def self.category_query_sql
    "SELECT 'category' AS type,
            c.name AS id,
            '/category/' || c.slug AS url,
            c.name AS title,
            NULL AS email,
            c.color,
            c.text_color
    FROM categories AS c
    JOIN categories_search s on s.id = c.id
    WHERE s.search_data @@ TO_TSQUERY(:locale, :query)
    ORDER BY topics_month desc
    LIMIT :limit
    "
  end

  def self.current_locale_long
    case I18n.locale         # Currently-present in /conf/locales/* only, sorry :-( Add as needed
      when :da then 'danish'
      when :de then 'german'
      when :en then 'english'
      when :es then 'spanish'
      when :fr then 'french'
      when :it then 'italian'
      when :nl then 'dutch'
      when :pt then 'portuguese'
      when :sv then 'swedish'
      else 'simple' # use the 'simple' stemmer for other languages
    end
  end

  # needs current user for secure categories
  def self.query(term, current_user, type_filter=nil, min_search_term_length=3)

    return nil if term.blank?

    # We are stripping only symbols taking place in FTS and simply sanitizing the rest.
    sanitized_term = PG::Connection.escape_string(term.gsub(/[:()&!]/,''))

    # really short terms are totally pointless
    return nil if sanitized_term.blank? || sanitized_term.length < min_search_term_length

    terms = sanitized_term.split
    terms.map! {|t| "#{t}:*"}

    args = {orig: sanitized_term, query: terms.join(" & "), locale: current_locale_long}

    if type_filter.present?
      raise Discourse::InvalidAccess.new("invalid type filter") unless Search.facets.include?(type_filter)
      sql = Search.send("#{type_filter}_query_sql")

      a = args.merge(limit: Search.per_facet * Search.facets.size)

      if type_filter.to_s == "post"
        db_result = post_query(current_user, :post, a)
      elsif type_filter.to_s == "topic"
        db_result = post_query(current_user, :topic, a)
      else
        db_result = ActiveRecord::Base.exec_sql(sql , a)
      end

    else

      db_result = []

      [user_query_sql, category_query_sql].each do |sql|
        db_result += ActiveRecord::Base.exec_sql(sql , args.merge(limit: (Search.per_facet + 1))).to_a
      end

      db_result += post_query(current_user, :topic, args.merge(limit: (Search.per_facet + 1))).to_a
    end

    db_result = db_result.to_a

    expected_topics = 0
    expected_topics = Search.facets.size unless type_filter.present?
    expected_topics = Search.per_facet * Search.facets.size if type_filter == 'topic'

    if expected_topics > 0
      db_result.each do |row|
        expected_topics -= 1 if row['type'] == 'topic'
      end
    end

    if expected_topics > 0
      tmp = post_query(current_user, :post, args.merge(limit: expected_topics * 3))

      topic_ids = Set.new db_result.map{|r| r["id"]}

      tmp = tmp.to_a
      tmp = tmp.reject{ |i|
        if topic_ids.include? i["id"]
          true
        else
          topic_ids << i["id"]
          false
        end
      }

      db_result += tmp[0..expected_topics-1]
    end

    # Group the results by type
    grouped = {}
    db_result.each do |row|
      type = row.delete('type')

      # Add the slug for topics
      if type == 'topic'
        new_slug = Slug.for(row['title'])
        new_slug = "topic" if new_slug.blank?
        row['url'].gsub!('slug', new_slug)
      end

      # Remove attributes when we know they don't matter
      if type == 'user'
        row['avatar_template'] = User.avatar_template(row['email'])
      end
      row.delete('email')
      row.delete('color') unless type == 'category'
      row.delete('text_color') unless type == 'category'

      grouped[type] ||= []
      grouped[type] << row
    end

    result = grouped.map do |type, results|
      more = type_filter.blank? && (results.size > Search.per_facet)
      results = results[0..([results.length, Search.per_facet].min - 1)] if type_filter.blank?
      {
        type: type,
        name: I18n.t("search.types.#{type}"),
        more: more,
        results: results
      }
    end

    result
  end

end
