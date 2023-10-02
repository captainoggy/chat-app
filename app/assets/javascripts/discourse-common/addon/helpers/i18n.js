import I18n from "I18n";
import { registerUnbound } from "discourse-common/lib/helpers";

export default function i18n(key, params) {
  return I18n.t(key, params);
}
registerUnbound("i18n", i18n);

registerUnbound("i18n-yes-no", (value, params) =>
  I18n.t(value ? "yes_value" : "no_value", params)
);
