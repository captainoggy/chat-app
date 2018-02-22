require 'rails_helper'

describe TopicViewSerializer do
  def serialize_topic(topic, user)
    topic_view = TopicView.new(topic.id, user)
    described_class.new(topic_view, scope: Guardian.new(user), root: false).as_json
  end

  let(:topic) { Fabricate(:topic) }
  let(:user) { Fabricate(:user) }

  describe '#featured_link and #featured_link_root_domain' do
    let(:featured_link) { 'http://meta.discourse.org' }

    describe 'when topic featured link is disable' do
      it 'should return the right attributes' do
        topic.update!(featured_link: featured_link)
        SiteSetting.topic_featured_link_enabled = false

        json = serialize_topic(topic, user)

        expect(json[:featured_link]).to eq(nil)
        expect(json[:featured_link_root_domain]).to eq(nil)
      end
    end

    describe 'when topic featured link is enabled' do
      it 'should return the right attributes' do
        topic.update!(featured_link: featured_link)

        json = serialize_topic(topic, user)

        expect(json[:featured_link]).to eq(featured_link)
        expect(json[:featured_link_root_domain]).to eq('discourse.org')
      end
    end
  end

  describe '#suggested_topics' do
    let(:topic2) { Fabricate(:topic) }

    before do
      TopicUser.update_last_read(user, topic2.id, 0, 0, 0)
    end

    describe 'when loading last chunk' do
      it 'should include suggested topics' do
        json = serialize_topic(topic, user)

        expect(json[:suggested_topics].first.id).to eq(topic2.id)
      end
    end

    describe 'when not loading last chunk' do
      let(:post) { Fabricate(:post, topic: topic) }
      let(:post2) { Fabricate(:post, topic: topic) }

      it 'should not include suggested topics' do
        post
        post2
        topic_view = TopicView.new(topic.id, user, post_ids: [post.id])
        topic_view.next_page
        json = described_class.new(topic_view, scope: Guardian.new(user), root: false).as_json

        expect(json[:suggested_topics]).to eq(nil)
      end
    end
  end

  let(:user) { Fabricate(:user) }
  let(:moderator) { Fabricate(:moderator) }
  let(:tag) { Fabricate(:tag) }
  let(:pm) do
    Fabricate(:private_message_topic, tags: [tag], topic_allowed_users: [
      Fabricate.build(:topic_allowed_user, user: moderator),
      Fabricate.build(:topic_allowed_user, user: user)
    ])
  end

  describe 'when tags added to private message topics' do
    before do
      SiteSetting.tagging_enabled = true
      SiteSetting.allow_staff_to_tag_pms = true
    end

    it "should not include the tag for normal users" do
      json = serialize_topic(pm, user)
      expect(json[:tags]).to eq(nil)
    end

    it "should include the tag for staff users" do
      json = serialize_topic(pm, moderator)
      expect(json[:tags]).to eq([tag.name])

      json = serialize_topic(pm, Fabricate(:admin))
      expect(json[:tags]).to eq([tag.name])
    end

    it "should not include the tag if pm tags disabled" do
      SiteSetting.allow_staff_to_tag_pms = false

      json = serialize_topic(pm, moderator)
      expect(json[:tags]).to eq(nil)

      json = serialize_topic(pm, Fabricate(:admin))
      expect(json[:tags]).to eq(nil)
    end
  end
end
