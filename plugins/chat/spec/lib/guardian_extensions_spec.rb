# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chat::GuardianExtensions do
  fab!(:user) { Fabricate(:user) }
  fab!(:staff) { Fabricate(:user, admin: true) }
  fab!(:chat_group) { Fabricate(:group) }
  fab!(:channel) { Fabricate(:category_channel) }
  fab!(:dm_channel) { Fabricate(:direct_message_chat_channel) }
  let(:guardian) { Guardian.new(user) }
  let(:staff_guardian) { Guardian.new(staff) }

  before do
    SiteSetting.chat_allowed_groups = chat_group.id
    chat_group.add(user)
  end

  it "cannot chat if the user is not in the Chat.allowed_group_ids" do
    SiteSetting.chat_allowed_groups = ""
    expect(guardian.can_chat?(user)).to eq(false)
  end

  it "staff can always chat regardless of chat_allowed_grups" do
    SiteSetting.chat_allowed_groups = ""
    expect(guardian.can_chat?(staff)).to eq(true)
  end

  describe "chat channel" do
    it "only staff can create channels" do
      expect(guardian.can_create_chat_channel?).to eq(false)
      expect(staff_guardian.can_create_chat_channel?).to eq(true)
    end

    it "only staff can edit chat channels" do
      expect(guardian.can_edit_chat_channel?).to eq(false)
      expect(staff_guardian.can_edit_chat_channel?).to eq(true)
    end

    it "only staff can close chat channels" do
      channel.update(status: :open)
      expect(guardian.can_change_channel_status?(channel, :closed)).to eq(false)
      expect(staff_guardian.can_change_channel_status?(channel, :closed)).to eq(true)
    end

    it "only staff can open chat channels" do
      channel.update(status: :closed)
      expect(guardian.can_change_channel_status?(channel, :open)).to eq(false)
      expect(staff_guardian.can_change_channel_status?(channel, :open)).to eq(true)
    end

    it "only staff can archive chat channels" do
      channel.update(status: :read_only)
      expect(guardian.can_change_channel_status?(channel, :archived)).to eq(false)
      expect(staff_guardian.can_change_channel_status?(channel, :archived)).to eq(true)
    end

    it "only staff can mark chat channels read_only" do
      channel.update(status: :open)
      expect(guardian.can_change_channel_status?(channel, :read_only)).to eq(false)
      expect(staff_guardian.can_change_channel_status?(channel, :read_only)).to eq(true)
    end

    describe "#can_see_chat_channel?" do
      context "for direct message channels" do
        fab!(:chatable) { Fabricate(:direct_message_channel) }
        fab!(:channel) { Fabricate(:dm_channel, chatable: chatable) }

        it "returns false if the user is not part of the direct message" do
          expect(guardian.can_see_chat_channel?(channel)).to eq(false)
        end

        it "returns true if the user is part of the direct message" do
          DirectMessageUser.create!(user: user, direct_message_channel_id: chatable.id)
          expect(guardian.can_see_chat_channel?(channel)).to eq(true)
        end
      end

      context "for category channel" do
        fab!(:category) { Fabricate(:category, read_restricted: true) }

        before { channel.update(chatable: category) }

        it "returns true if the user can see the category" do
          expect(Guardian.new(user).can_see_chat_channel?(channel)).to eq(false)
          group = Fabricate(:group)
          CategoryGroup.create(group: group, category: category)
          GroupUser.create(group: group, user: user)

          # have to make a new instance of guardian because `user.secure_category_ids`
          # is memoized there
          expect(Guardian.new(user).can_see_chat_channel?(channel)).to eq(true)
        end
      end
    end

    describe "#can_flag_in_chat_channel?" do
      alias_matcher :be_able_to_flag_in_chat_channel, :be_can_flag_in_chat_channel

      context "when channel is a direct message channel" do
        let(:channel) { Fabricate(:dm_channel) }

        it "returns false" do
          expect(guardian).not_to be_able_to_flag_in_chat_channel(channel)
        end
      end

      context "when channel is a category channel" do
        it "returns true" do
          expect(guardian).to be_able_to_flag_in_chat_channel(channel)
        end
      end

      context "with a private channel" do
        let(:private_group) { Fabricate(:group) }
        let(:private_category) { Fabricate(:private_category, group: private_group) }
        let(:private_channel) { Fabricate(:category_channel, chatable: private_category) }

        context "when the user can't see the channel" do
          it "returns false" do
            expect(guardian).not_to be_able_to_flag_in_chat_channel(private_channel)
          end
        end

        context "when the user can see the channel" do
          before { private_group.add(user) }

          it "returns true" do
            expect(guardian).to be_able_to_flag_in_chat_channel(private_channel)
          end
        end
      end
    end

    describe "#can_moderate_chat?" do
      context "for category channel" do
        fab!(:category) { Fabricate(:category, read_restricted: true) }

        before { channel.update(chatable: category) }

        it "returns true for staff and false for regular users" do
          expect(staff_guardian.can_moderate_chat?(channel.chatable)).to eq(true)
          expect(guardian.can_moderate_chat?(channel.chatable)).to eq(false)
        end

        context "when enable_category_group_moderation is true" do
          before { SiteSetting.enable_category_group_moderation = true }

          it "returns true if the regular user is part of the reviewable_by_group for the category" do
            moderator = Fabricate(:user)
            mods = Fabricate(:group)
            mods.add(moderator)
            category.update!(reviewable_by_group: mods)
            expect(Guardian.new(Fabricate(:admin)).can_moderate_chat?(channel.chatable)).to eq(true)
            expect(Guardian.new(moderator).can_moderate_chat?(channel.chatable)).to eq(true)
          end
        end
      end

      context "for DM channel" do
        fab!(:dm_channel) { DirectMessageChannel.create! }

        before { channel.update(chatable_type: "DirectMessageType", chatable: dm_channel) }

        it "returns true for staff and false for regular users" do
          expect(staff_guardian.can_moderate_chat?(channel.chatable)).to eq(true)
          expect(guardian.can_moderate_chat?(channel.chatable)).to eq(false)
        end
      end
    end

    describe "#can_restore_chat?" do
      fab!(:message) { Fabricate(:chat_message, chat_channel: channel, user: user) }
      fab!(:chatable) { Fabricate(:category) }

      context "when channel is closed" do
        before { channel.update!(status: :closed) }

        it "disallows a owner to restore" do
          expect(guardian.can_restore_chat?(message, chatable)).to eq(false)
        end

        it "allows a staff to restore" do
          expect(staff_guardian.can_restore_chat?(message, chatable)).to eq(true)
        end
      end

      context "when chatable is a direct message" do
        fab!(:chatable) { DirectMessageChannel.create! }

        it "allows owner to restore" do
          expect(guardian.can_restore_chat?(message, chatable)).to eq(true)
        end

        it "allows staff to restore" do
          expect(staff_guardian.can_restore_chat?(message, chatable)).to eq(true)
        end
      end

      context "when user is not owner of the message" do
        fab!(:message) { Fabricate(:chat_message, chat_channel: channel, user: Fabricate(:user)) }

        context "when chatable is a category" do
          context "when category is not restricted" do
            it "allows staff to restore" do
              expect(staff_guardian.can_restore_chat?(message, chatable)).to eq(true)
            end

            it "disallows any user to restore" do
              expect(guardian.can_restore_chat?(message, chatable)).to eq(false)
            end
          end

          context "when category is restricted" do
            fab!(:chatable) { Fabricate(:category, read_restricted: true) }

            it "allows staff to restore" do
              expect(staff_guardian.can_restore_chat?(message, chatable)).to eq(true)
            end

            it "disallows any user to restore" do
              expect(guardian.can_restore_chat?(message, chatable)).to eq(false)
            end

            context "when group moderation is enabled" do
              before { SiteSetting.enable_category_group_moderation = true }

              it "allows a group moderator to restore" do
                moderator = Fabricate(:user)
                mods = Fabricate(:group)
                mods.add(moderator)
                chatable.update!(reviewable_by_group: mods)
                expect(Guardian.new(moderator).can_restore_chat?(message, chatable)).to eq(true)
              end
            end
          end

          context "when chatable is a direct message" do
            fab!(:chatable) { DirectMessageChannel.create! }

            it "allows staff to restore" do
              expect(staff_guardian.can_restore_chat?(message, chatable)).to eq(true)
            end

            it "disallows any user to restore" do
              expect(guardian.can_restore_chat?(message, chatable)).to eq(false)
            end
          end
        end
      end

      context "when user is owner of the message" do
        context "when chatable is a category" do
          it "allows to restore if owner can see category" do
            expect(guardian.can_restore_chat?(message, chatable)).to eq(true)
          end

          context "when category is restricted" do
            fab!(:chatable) { Fabricate(:category, read_restricted: true) }

            it "disallows to restore if owner can't see category" do
              expect(guardian.can_restore_chat?(message, chatable)).to eq(false)
            end

            it "allows staff to restore" do
              expect(staff_guardian.can_restore_chat?(message, chatable)).to eq(true)
            end
          end
        end

        context "when chatable is a direct message" do
          fab!(:chatable) { DirectMessageChannel.create! }

          it "allows staff to restore" do
            expect(staff_guardian.can_restore_chat?(message, chatable)).to eq(true)
          end

          it "allows owner to restore" do
            expect(guardian.can_restore_chat?(message, chatable)).to eq(true)
          end
        end
      end
    end

    describe "#can_delete_category?" do
      alias_matcher :be_able_to_delete_category, :be_can_delete_category

      let(:category) { channel.chatable }

      context "when category has no channel" do
        before do
          category.category_channel.destroy
          category.reload
        end

        it "allows to delete the category" do
          expect(staff_guardian).to be_able_to_delete_category(category)
        end
      end

      context "when category has a channel" do
        it "does not allow to delete the category" do
          expect(staff_guardian).not_to be_able_to_delete_category(category)
        end
      end
    end
  end

  describe "#can_create_channel_message?" do
    context "when user is staff" do
      it "returns true if the channel is open" do
        channel.update!(status: :open)
        expect(staff_guardian.can_create_channel_message?(channel)).to eq(true)
      end

      it "returns true if the channel is closed" do
        channel.update!(status: :closed)
        expect(staff_guardian.can_create_channel_message?(channel)).to eq(true)
      end

      it "returns false if the channel is archived" do
        channel.update!(status: :archived)
        expect(staff_guardian.can_create_channel_message?(channel)).to eq(false)
      end

      context "for direct message channels" do
        it "returns true if the channel is open" do
          dm_channel.update!(status: :open)
          expect(staff_guardian.can_create_channel_message?(dm_channel)).to eq(true)
        end
      end
    end

    context "when user is not staff" do
      it "returns true if the channel is open" do
        channel.update!(status: :open)
        expect(guardian.can_create_channel_message?(channel)).to eq(true)
      end

      it "returns false if the channel is closed" do
        channel.update!(status: :closed)
        expect(guardian.can_create_channel_message?(channel)).to eq(false)
      end

      it "returns false if the channel is archived" do
        channel.update!(status: :archived)
        expect(guardian.can_create_channel_message?(channel)).to eq(false)
      end

      context "for direct message channels" do
        before { Group.refresh_automatic_groups! }

        it "it still allows the user to message even if they are not in direct_message_enabled_groups because they are not creating the channel" do
          SiteSetting.direct_message_enabled_groups = Group::AUTO_GROUPS[:trust_level_4]
          dm_channel.update!(status: :open)
          expect(guardian.can_create_channel_message?(dm_channel)).to eq(true)
        end
      end
    end
  end
end
