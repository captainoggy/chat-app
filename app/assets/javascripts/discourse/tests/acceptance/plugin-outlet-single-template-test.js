import {
  acceptance,
  count,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import { hbs } from "ember-cli-htmlbars";
import { test } from "qunit";
import { visit } from "@ember/test-helpers";
import { registerTemplateModule } from "../helpers/template-module-helper";

const CONNECTOR_MODULE =
  "discourse/theme-12/templates/connectors/user-profile-primary/hello";

acceptance("Plugin Outlet - Single Template", function (needs) {
  needs.hooks.beforeEach(() => {
    registerTemplateModule(
      CONNECTOR_MODULE,
      hbs`<span class='hello-username'>{{model.username}}</span>`
    );
  });

  test("Renders a template into the outlet", async function (assert) {
    await visit("/u/eviltrout");
    assert.strictEqual(
      count(".user-profile-primary-outlet.hello"),
      1,
      "it has class names"
    );
    assert.strictEqual(
      query(".hello-username").innerText,
      "eviltrout",
      "it renders into the outlet"
    );
  });
});
