/**
  A data model for containing a list of categories

  @class CategoryList
  @extends Discourse.Model
  @namespace Discourse
  @module Discourse
**/
Discourse.CategoryList = Discourse.Model.extend({});

Discourse.CategoryList.reopenClass({

  categoriesFrom: function(result) {
    var categories = Em.A();
    var users = this.extractByKey(result.featured_users, Discourse.User);


    result.category_list.categories.each(function(c) {
      if (c.featured_user_ids) {
        c.featured_users = c.featured_user_ids.map(function(u) {
          return users[u];
        });
      }
      if (c.topics) {
        c.topics = c.topics.map(function(t) {
          return Discourse.Topic.create(t);
        });
      }

      if (c.is_uncategorized) {
        var uncategorized = Discourse.Category.uncategorizedInstance();
        uncategorized.setProperties({
          topics: c.topics,
          featured_users: c.featured_users,
          topics_week: c.topics_week,
          topics_month: c.topics_month,
          topics_year: c.topics_year
        });
        categories.pushObject(uncategorized);
      } else {
        categories.pushObject(Discourse.Category.create(c));
      }
    });
    return categories;
  },

  list: function(filter) {
    var route = this;
    var finder = null;
    if (filter === 'categories') {
      finder = PreloadStore.getAndRemove("categories_list", function() {
        return Discourse.ajax("/categories.json")
      });
    } else {
      finder = Discourse.ajax("/" + filter + ".json")
    }

    return finder.then(function(result) {
      var categoryList = Discourse.TopicList.create();
      categoryList.set('can_create_category', result.category_list.can_create_category);
      categoryList.set('can_create_topic', result.category_list.can_create_topic);
      categoryList.set('categories', route.categoriesFrom(result));
      categoryList.set('loaded', true);
      return categoryList;
    });
  }

});


