import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

export default class Types extends Component {
  @service search;

  get filteredResultTypes() {
    // return only topic result types
    if (this.args.topicResultsOnly) {
      return this.args.resultTypes.filter(
        (resultType) => resultType.type === "topic"
      );
    }

    // return all result types minus topics
    return this.args.resultTypes.filter(
      (resultType) => resultType.type !== "topic"
    );
  }

  @action
  onClick() {
    this.args.closeSearchMenu();
  }

  @action
  onKeydown(e) {
    if (e.key === "Escape") {
      this.args.closeSearchMenu();
      e.preventDefault();
      return false;
    }

    this.search.handleResultInsertion(e);
    this.search.handleArrowUpOrDown(e);
  }
}
