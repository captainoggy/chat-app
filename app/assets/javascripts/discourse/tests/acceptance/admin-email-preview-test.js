import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { click, visit, waitUntil } from "@ember/test-helpers";
import { test } from "qunit";

acceptance("Admin - email-preview", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/admin/email/preview-digest.json", () =>
      helper.response(200, {
        html_content: "<span>Hello world</span>",
        text_content: "<span>Not actually html</span>",
      })
    );
  });

  test("preview rendering", async function (assert) {
    await visit("/admin/email/preview-digest");
    const iframe = query(".preview-output iframe");

    // Rendered as a separate document, so Ember's built-in waiters don't work properly
    await waitUntil(() => iframe.contentWindow.document.body);

    const iframeBody = iframe.contentWindow.document.body;

    assert.strictEqual(
      iframeBody.querySelector("span").innerText,
      "Hello world",
      "html content is rendered inside iframe"
    );

    await click("a.show-text-link");
    assert
      .dom(".preview-output pre")
      .hasText(
        "<span>Not actually html</span>",
        "text content is escaped correctly"
      );
  });
});
