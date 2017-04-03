require 'rails_helper'
require_dependency 'jobs/scheduled/grant_new_user_of_the_month_badges'

describe Jobs::GrantNewUserOfTheMonthBadges do

  let(:granter) { described_class.new }

  it "runs correctly" do
    user = Fabricate(:user, created_at: 1.week.ago)
    p = Fabricate(:post, user: user)
    Fabricate(:post, user: user)

    old_user = Fabricate(:user, created_at: 6.months.ago)
    PostAction.act(old_user, p, PostActionType.types[:like])
    old_user = Fabricate(:user, created_at: 6.months.ago)
    PostAction.act(old_user, p, PostActionType.types[:like])

    granter.execute({})

    badge = user.user_badges.where(badge_id: Badge::NewUserOfTheMonth)
    expect(badge).to be_present
  end

  describe '.scores' do

    it "doesn't award it to accounts over a month old" do
      user = Fabricate(:user, created_at: 2.months.ago)
      Fabricate(:post, user: user)
      p = Fabricate(:post, user: user)
      old_user = Fabricate(:user, created_at: 6.months.ago)
      PostAction.act(old_user, p, PostActionType.types[:like])
      old_user = Fabricate(:user, created_at: 6.months.ago)
      PostAction.act(old_user, p, PostActionType.types[:like])

      expect(granter.scores.keys).not_to include(user.id)
    end

    it "doesn't score users who haven't posted in two topics" do
      user = Fabricate(:user, created_at: 1.week.ago)
      p = Fabricate(:post, user: user)
      old_user = Fabricate(:user, created_at: 6.months.ago)
      PostAction.act(old_user, p, PostActionType.types[:like])
      old_user = Fabricate(:user, created_at: 6.months.ago)
      PostAction.act(old_user, p, PostActionType.types[:like])

      expect(granter.scores.keys).not_to include(user.id)
    end

    it "requires at least two likes to be considered" do
      user = Fabricate(:user, created_at: 1.week.ago)
      Fabricate(:post, user: user)
      p = Fabricate(:post, user: user)
      old_user = Fabricate(:user, created_at: 6.months.ago)
      PostAction.act(old_user, p, PostActionType.types[:like])

      expect(granter.scores.keys).not_to include(user.id)
    end

    it "returns scores for accounts created within the last month" do
      user = Fabricate(:user, created_at: 1.week.ago)
      Fabricate(:post, user: user)
      p = Fabricate(:post, user: user)
      old_user = Fabricate(:user, created_at: 6.months.ago)
      PostAction.act(old_user, p, PostActionType.types[:like])
      old_user = Fabricate(:user, created_at: 6.months.ago)
      PostAction.act(old_user, p, PostActionType.types[:like])

      expect(granter.scores.keys).to include(user.id)
    end

    it "likes from older accounts are scored higher" do
      user = Fabricate(:user, created_at: 1.week.ago)
      p = Fabricate(:post, user: user)
      Fabricate(:post, user: user)

      new_user = Fabricate(:user, created_at: 2.days.ago)
      med_user = Fabricate(:user, created_at: 3.weeks.ago)
      old_user = Fabricate(:user, created_at: 6.months.ago)

      PostAction.act(new_user, p, PostActionType.types[:like])
      PostAction.act(med_user, p, PostActionType.types[:like])
      PostAction.act(old_user, p, PostActionType.types[:like])
      expect(granter.scores[user.id]).to eq(0.375)

      # It goes down the more they post
      Fabricate(:post, user: user)
      expect(granter.scores[user.id]).to eq(0.25)
    end

    it "is limited to two accounts" do
      u1 = Fabricate(:user, created_at: 1.week.ago)
      u2 = Fabricate(:user, created_at: 2.weeks.ago)
      u3 = Fabricate(:user, created_at: 3.weeks.ago)

      ou1 = Fabricate(:user, created_at: 6.months.ago)
      ou2 = Fabricate(:user, created_at: 6.months.ago)

      p = Fabricate(:post, user: u1)
      Fabricate(:post, user: u1)
      PostAction.act(ou1, p, PostActionType.types[:like])
      PostAction.act(ou2, p, PostActionType.types[:like])

      p = Fabricate(:post, user: u2)
      Fabricate(:post, user: u2)
      PostAction.act(ou1, p, PostActionType.types[:like])
      PostAction.act(ou2, p, PostActionType.types[:like])

      p = Fabricate(:post, user: u3)
      Fabricate(:post, user: u3)
      PostAction.act(ou1, p, PostActionType.types[:like])
      PostAction.act(ou2, p, PostActionType.types[:like])

      expect(granter.scores.keys.size).to eq(2)
    end

  end

end
