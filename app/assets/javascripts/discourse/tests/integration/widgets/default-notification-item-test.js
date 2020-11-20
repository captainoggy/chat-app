import {
  discourseModule,
  queryAll,
} from "discourse/tests/helpers/qunit-helpers";
import componentTest, {
  setupRenderingTest,
} from "discourse/tests/helpers/component-test";
import EmberObject from "@ember/object";
import pretender from "discourse/tests/helpers/create-pretender";

discourseModule(
  "Integration | Component | Widget | default-notification-item",
  function (hooks) {
    setupRenderingTest(hooks);

    componentTest("sets notification as read on middle click", {
      template: '{{mount-widget widget="default-notification-item" args=args}}',
      beforeEach() {
        this.set(
          "args",
          EmberObject.create({
            id: 3,
            user_id: 1,
            notification_type: 6,
            read: false,
            created_at: "2020-01-01T12:00:00.000Z",
            post_number: 1,
            topic_id: 10,
            fancy_title: "Greetings!",
            slug: "greetings",
            data: {
              topic_title: "Greetings!",
              original_post_id: 14,
              original_post_type: 1,
              original_username: "discobot",
              revision_number: null,
              display_username: "discobot",
            },
          })
        );
      },
      async test(assert) {
        let requests = 0;
        pretender.put("/notifications/mark-read", (request) => {
          ++requests;

          assert.equal(
            request.requestBody,
            `id=${this.args.id}`,
            "it sets correct request parameters"
          );

          return [
            200,
            { "Content-Type": "application/json" },
            { success: true },
          ];
        });

        assert.equal(queryAll("li.read").length, 0);

        await $(document).trigger(
          $.Event("mouseup", {
            target: queryAll("li")[0],
            button: 1,
            which: 2,
          })
        );

        assert.equal(queryAll("li.read").length, 1);
        assert.equal(requests, 1);
      },
    });
  }
);
