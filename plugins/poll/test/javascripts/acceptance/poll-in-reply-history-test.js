import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance, exists } from "discourse/tests/helpers/qunit-helpers";

acceptance("Poll in a post reply history", function (needs) {
  needs.user();
  needs.settings({ poll_enabled: true });

  needs.pretender((server, helper) => {
    server.get("/t/topic_with_poll_in_post_reply_history.json", () => {
      return helper.response({
        post_stream: {
          posts: [
            {
              id: 82,
              name: null,
              username: "admin1",
              avatar_template:
                "/letter_avatar_proxy/v4/letter/a/bbce88/{size}.png",
              created_at: "2021-01-25T13:08:27.385Z",
              cooked: "<p>A reply to the poll.</p>",
              post_number: 4,
              post_type: 1,
              updated_at: "2021-01-25T13:08:27.385Z",
              reply_count: 0,
              reply_to_post_number: 2,
              quote_count: 0,
              incoming_link_count: 0,
              reads: 1,
              readers_count: 0,
              score: 0.2,
              yours: true,
              topic_id: 25,
              topic_slug: "topic-with-a-poll-in-a-post-reply-history",
              display_username: null,
              primary_group_name: null,
              flair_url: null,
              flair_bg_color: null,
              flair_color: null,
              version: 1,
              can_edit: true,
              can_delete: true,
              can_recover: false,
              can_wiki: true,
              read: true,
              user_title: null,
              reply_to_user: {
                username: "admin1",
                avatar_template:
                  "/letter_avatar_proxy/v4/letter/a/bbce88/{size}.png",
              },
              bookmarked: false,
              bookmarks: [],
              actions_summary: [
                {
                  id: 3,
                  can_act: true,
                },
                {
                  id: 4,
                  can_act: true,
                },
                {
                  id: 8,
                  can_act: true,
                },
                {
                  id: 7,
                  can_act: true,
                },
              ],
              moderator: false,
              admin: true,
              staff: true,
              user_id: 3,
              hidden: false,
              trust_level: 1,
              deleted_at: null,
              user_deleted: false,
              edit_reason: null,
              can_view_edit_history: true,
              wiki: false,
              reviewable_id: 0,
              reviewable_score_count: 0,
              reviewable_score_pending_count: 0,
            },
          ],
          stream: [82],
        },
        timeline_lookup: [[1, 0]],
        suggested_topics: [
          {
            id: 7,
            title: "Welcome to Discourse",
            fancy_title: "Welcome to Discourse",
            slug: "welcome-to-discourse",
            posts_count: 1,
            reply_count: 0,
            highest_post_number: 1,
            image_url: null,
            created_at: "2021-01-07T15:36:44.707Z",
            last_posted_at: "2021-01-07T15:36:44.750Z",
            bumped: true,
            bumped_at: "2021-01-07T15:36:44.750Z",
            archetype: "regular",
            unseen: false,
            pinned: true,
            unpinned: null,
            excerpt:
              "The first paragraph of this pinned topic will be visible as a welcome message to all new visitors on your homepage. It’s important! Edit this into a brief description of your community: Who is it for? What can they fi&hellip;",
            visible: true,
            closed: false,
            archived: false,
            bookmarked: null,
            liked: null,
            like_count: 0,
            views: 1,
            category_id: 1,
            featured_link: null,
            posters: [
              {
                extras: "latest single",
                description: "Original Poster, Most Recent Poster",
                user: {
                  id: -1,
                  username: "system",
                  name: "system",
                  avatar_template:
                    "http://localhost:3000/images/discourse-logo-sketch-small.png",
                },
              },
            ],
          },
          {
            id: 20,
            title: "Polls testing. Just one poll in the comment",
            fancy_title: "Polls testing. Just one poll in the comment",
            slug: "polls-testing-just-one-poll-in-the-comment",
            posts_count: 3,
            reply_count: 1,
            highest_post_number: 3,
            image_url: null,
            created_at: "2021-01-21T09:21:35.102Z",
            last_posted_at: "2021-01-22T09:35:33.543Z",
            bumped: true,
            bumped_at: "2021-01-22T09:35:33.543Z",
            archetype: "regular",
            unseen: false,
            last_read_post_number: 3,
            unread_posts: 0,
            pinned: false,
            unpinned: null,
            visible: true,
            closed: false,
            archived: false,
            notification_level: 2,
            bookmarked: false,
            bookmarks: [],
            liked: false,
            like_count: 0,
            views: 3,
            category_id: 1,
            featured_link: null,
            posters: [
              {
                extras: null,
                description: "Original Poster",
                user: {
                  id: 2,
                  username: "andrey1",
                  name: "andrey1",
                  avatar_template:
                    "/letter_avatar_proxy/v4/letter/a/c0e974/{size}.png",
                },
              },
              {
                extras: "latest",
                description: "Most Recent Poster",
                user: {
                  id: 3,
                  username: "admin1",
                  name: null,
                  avatar_template:
                    "/letter_avatar_proxy/v4/letter/a/bbce88/{size}.png",
                },
              },
            ],
          },
          {
            id: 22,
            title: "Polls testing. The whole test",
            fancy_title: "Polls testing. The whole test",
            slug: "polls-testing-the-whole-test",
            posts_count: 12,
            reply_count: 8,
            highest_post_number: 12,
            image_url: null,
            created_at: "2021-01-21T09:55:20.135Z",
            last_posted_at: "2021-01-22T11:59:31.561Z",
            bumped: true,
            bumped_at: "2021-01-22T11:59:31.561Z",
            archetype: "regular",
            unseen: false,
            last_read_post_number: 12,
            unread_posts: 0,
            pinned: false,
            unpinned: null,
            visible: true,
            closed: false,
            archived: false,
            notification_level: 2,
            bookmarked: false,
            bookmarks: [],
            liked: false,
            like_count: 0,
            views: 4,
            category_id: 1,
            featured_link: null,
            posters: [
              {
                extras: null,
                description: "Original Poster",
                user: {
                  id: 2,
                  username: "andrey1",
                  name: "andrey1",
                  avatar_template:
                    "/letter_avatar_proxy/v4/letter/a/c0e974/{size}.png",
                },
              },
              {
                extras: "latest",
                description: "Most Recent Poster",
                user: {
                  id: 3,
                  username: "admin1",
                  name: null,
                  avatar_template:
                    "/letter_avatar_proxy/v4/letter/a/bbce88/{size}.png",
                },
              },
            ],
          },
        ],
        id: 25,
        title: "Topic with a poll in a post reply history",
        fancy_title: "Topic with a poll in a post reply history",
        posts_count: 4,
        created_at: "2021-01-25T13:07:31.670Z",
        views: 2,
        reply_count: 2,
        like_count: 0,
        last_posted_at: "2021-01-25T13:08:27.385Z",
        visible: true,
        closed: false,
        archived: false,
        has_summary: false,
        archetype: "regular",
        slug: "topic-with-a-poll-in-a-post-reply-history",
        category_id: 1,
        word_count: 25,
        deleted_at: null,
        user_id: 3,
        featured_link: null,
        pinned_globally: false,
        pinned_at: null,
        pinned_until: null,
        image_url: null,
        slow_mode_seconds: 0,
        draft: null,
        draft_key: "topic_25",
        draft_sequence: 4,
        posted: true,
        unpinned: null,
        pinned: false,
        current_post_number: 4,
        highest_post_number: 4,
        last_read_post_number: 4,
        last_read_post_id: 82,
        deleted_by: null,
        has_deleted: false,
        actions_summary: [
          {
            id: 4,
            count: 0,
            hidden: false,
            can_act: true,
          },
          {
            id: 8,
            count: 0,
            hidden: false,
            can_act: true,
          },
          {
            id: 7,
            count: 0,
            hidden: false,
            can_act: true,
          },
        ],
        chunk_size: 20,
        bookmarked: false,
        bookmarks: [],
        topic_timer: null,
        message_bus_last_id: 4,
        participant_count: 1,
        show_read_indicator: false,
        thumbnails: null,
        details: {
          can_edit: true,
          notification_level: 3,
          notifications_reason_id: 1,
          can_move_posts: true,
          can_delete: true,
          can_remove_allowed_users: true,
          can_invite_to: true,
          can_invite_via_email: true,
          can_create_post: true,
          can_reply_as_new_topic: true,
          can_flag_topic: true,
          can_convert_topic: true,
          can_review_topic: true,
          can_close_topic: true,
          can_archive_topic: true,
          can_split_merge_topic: true,
          can_edit_staff_notes: true,
          can_toggle_topic_visibility: true,
          can_moderate_category: true,
          can_remove_self_id: 3,
          participants: [
            {
              id: 3,
              username: "admin1",
              name: null,
              avatar_template:
                "/letter_avatar_proxy/v4/letter/a/bbce88/{size}.png",
              post_count: 4,
              primary_group_name: null,
              flair_url: null,
              flair_color: null,
              flair_bg_color: null,
            },
          ],
          created_by: {
            id: 3,
            username: "admin1",
            name: null,
            avatar_template:
              "/letter_avatar_proxy/v4/letter/a/bbce88/{size}.png",
          },
          last_poster: {
            id: 3,
            username: "admin1",
            name: null,
            avatar_template:
              "/letter_avatar_proxy/v4/letter/a/bbce88/{size}.png",
          },
        },
      });
    });

    server.get("/posts/82/reply-history", () => {
      return helper.response([
        {
          id: 80,
          name: null,
          username: "admin1",
          avatar_template: "/letter_avatar_proxy/v4/letter/a/bbce88/{size}.png",
          created_at: "2021-01-25T13:07:58.995Z",
          cooked:
            '<p>The poll:</p>\n<div class="poll" data-poll-status="open" data-poll-name="poll">\n<div>\n<div class="poll-container">\n<ul>\n<li data-poll-option-id="5b8ee5ba2a43e258f93dbef9264bf1ad">Option A</li>\n<li data-poll-option-id="6872645f5d8ef2311883617a3a7d381b">Option B</li>\n</ul>\n</div>\n<div class="poll-info">\n<p>\n<span class="info-number">0</span>\n<span class="info-label">voters</span>\n</p>\n</div>\n</div>\n</div>',
          post_number: 2,
          post_type: 1,
          updated_at: "2021-01-25T13:07:58.995Z",
          reply_count: 2,
          reply_to_post_number: null,
          quote_count: 0,
          incoming_link_count: 0,
          reads: 1,
          readers_count: 0,
          score: 10.2,
          yours: false,
          topic_id: 25,
          topic_slug: "topic-with-a-poll-in-a-post-reply-history",
          display_username: null,
          primary_group_name: null,
          flair_url: null,
          flair_bg_color: null,
          flair_color: null,
          version: 1,
          can_edit: false,
          can_delete: false,
          can_recover: false,
          can_wiki: false,
          user_title: null,
          bookmarked: false,
          bookmarks: [],
          actions_summary: [],
          moderator: false,
          admin: true,
          staff: true,
          user_id: 3,
          hidden: false,
          trust_level: 1,
          deleted_at: null,
          user_deleted: false,
          edit_reason: null,
          can_view_edit_history: true,
          wiki: false,
          polls: [
            {
              name: "poll",
              type: "regular",
              status: "open",
              results: "always",
              options: [
                {
                  id: "5b8ee5ba2a43e258f93dbef9264bf1ad",
                  html: "Option A",
                  votes: 0,
                },
                {
                  id: "6872645f5d8ef2311883617a3a7d381b",
                  html: "Option B",
                  votes: 0,
                },
              ],
              voters: 0,
              chart_type: "bar",
              title: null,
            },
          ],
        },
      ]);
    });
  });

  test("renders and extends", async function (assert) {
    await visit("/t/-/topic_with_poll_in_post_reply_history");
    await click(".reply-to-tab");
    assert.ok(exists(".poll"), "poll is rendered");
    assert.ok(exists(".poll-buttons"), "poll is extended");
  });
});
