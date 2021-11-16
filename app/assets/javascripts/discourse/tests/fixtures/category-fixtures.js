export default {
  "/c/1/show.json": {
    category: {
      id: 1,
      name: "bug",
      color: "e9dd00",
      text_color: "000000",
      slug: "bug",
      topic_count: 2030,
      post_count: 13418,
      description:
        "A bug report means something is broken, preventing normal/typical use of Discourse. Do be sure to search prior to submitting bugs. Include repro steps, and only describe one bug per topic please.",
      description_text:
        "A bug report means something is broken, preventing normal/typical use of Discourse. Do be sure to search prior to submitting bugs. Include repro steps, and only describe one bug per topic please.",
      topic_url: "/t/category-definition-for-bug/2",
      read_restricted: false,
      permission: null,
      notification_level: null,
      available_groups: [
        "admins",
        "discourse",
        "everyone",
        "moderators",
        "staff",
        "translators",
        "trust_level_0",
        "trust_level_1",
        "trust_level_2",
        "trust_level_3",
        "trust_level_4"
      ],
      auto_close_hours: null,
      auto_close_based_on_last_post: false,
      group_permissions: [{ permission_type: 1, group_name: "everyone" }],
      position: 25,
      cannot_delete_reason:
        "Can't delete this category because it has 2030 topics. Oldest topic is <a href=\"https://localhost:3000/t/when-a-new-post-appears-in-a-topic-the-bookmark-isn-t-updated/39\">When a new post appears in a topic, the bookmark isn't updated</a>.",
      allow_badges: true,
      custom_fields: {}
    }
  },
  "/c/11/show.json": {
    category: {
      id: 11,
      name: "testing",
      color: "0088CC",
      text_color: "FFFFFF",
      slug: "testing",
      can_edit: true
    }
  },
  "/c/2481/show.json": {
    category: {
      id: 2481,
      name: "restricted-group",
      color: "e9dd00",
      text_color: "000000",
      slug: "restricted-group",
      read_restricted: true,
      permission: null,
      group_permissions: [{ permission_type: 1, group_name: "moderators" }],
    }
  },

};
