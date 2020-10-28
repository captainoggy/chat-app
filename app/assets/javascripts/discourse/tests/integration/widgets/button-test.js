import { queryAll } from "discourse/tests/helpers/qunit-helpers";
import {
  moduleForWidget,
  widgetTest,
} from "discourse/tests/helpers/widget-test";

moduleForWidget("button");

widgetTest("icon only button", {
  template: '{{mount-widget widget="button" args=args}}',

  beforeEach() {
    this.set("args", { icon: "far-smile" });
  },

  test(assert) {
    assert.ok(
      queryAll("button.btn.btn-icon.no-text").length,
      "it has all the classes"
    );
    assert.ok(
      queryAll("button .d-icon.d-icon-far-smile").length,
      "it has the icon"
    );
  },
});

widgetTest("icon and text button", {
  template: '{{mount-widget widget="button" args=args}}',

  beforeEach() {
    this.set("args", { icon: "plus", label: "topic.create" });
  },

  test(assert) {
    assert.ok(
      queryAll("button.btn.btn-icon-text").length,
      "it has all the classes"
    );
    assert.ok(queryAll("button .d-icon.d-icon-plus").length, "it has the icon");
    assert.ok(
      queryAll("button span.d-button-label").length,
      "it has the label"
    );
  },
});

widgetTest("text only button", {
  template: '{{mount-widget widget="button" args=args}}',

  beforeEach() {
    this.set("args", { label: "topic.create" });
  },

  test(assert) {
    assert.ok(queryAll("button.btn.btn-text").length, "it has all the classes");
    assert.ok(
      queryAll("button span.d-button-label").length,
      "it has the label"
    );
  },
});
