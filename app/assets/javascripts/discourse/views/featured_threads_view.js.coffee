window.Discourse.FeaturedTopicsView = Ember.View.extend
  templateName: 'featured_topics'
  classNames: ['category-list-item'] 

  init: ->
    @._super()
    @set('context', @get('content'))