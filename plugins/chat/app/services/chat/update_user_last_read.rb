# frozen_string_literal: true

module Chat
  # Service responsible for updating the last read message id of a membership.
  #
  # @example
  #  Chat::UpdateUserLastRead.call(channel_id: 2, message_id: 3, guardian: guardian)
  #
  class UpdateUserLastRead
    include ::Service::Base

    # @!method call(channel_id:, message_id:, guardian:)
    #   @param [Integer] channel_id
    #   @param [Integer] message_id
    #   @param [Guardian] guardian
    #   @return [Service::Base::Context]

    contract
    model :channel
    model :active_membership
    policy :invalid_access
    policy :ensure_message_exists
    policy :ensure_message_id_recency
    step :update_last_read_message_id
    step :mark_associated_mentions_as_read
    step :publish_new_last_read_to_clients

    # @!visibility private
    class Contract
      attribute :message_id, :integer
      attribute :channel_id, :integer

      validates :message_id, :channel_id, presence: true
    end

    private

    def fetch_channel(contract:, **)
      ::Chat::Channel.find_by(id: contract.channel_id)
    end

    def fetch_active_membership(guardian:, channel:, **)
      ::Chat::ChannelMembershipManager.new(channel).find_for_user(guardian.user, following: true)
    end

    def invalid_access(guardian:, active_membership:, **)
      guardian.can_join_chat_channel?(active_membership.chat_channel)
    end

    def ensure_message_exists(channel:, contract:, **)
      ::Chat::Message.with_deleted.exists?(chat_channel_id: channel.id, id: contract.message_id)
    end

    def ensure_message_id_recency(contract:, active_membership:, **)
      !active_membership.last_read_message_id ||
        contract.message_id >= active_membership.last_read_message_id
    end

    def update_last_read_message_id(contract:, active_membership:, **)
      active_membership.update!(last_read_message_id: contract.message_id)
    end

    def mark_associated_mentions_as_read(active_membership:, contract:, **)
      Chat::Action::MarkMentionsRead.call(
        active_membership.user,
        channel_ids: [active_membership.chat_channel.id],
        message_id: contract.message_id,
      )
    end

    def publish_new_last_read_to_clients(guardian:, channel:, contract:, **)
      ::Chat::Publisher.publish_user_tracking_state(guardian.user, channel.id, contract.message_id)
    end
  end
end
