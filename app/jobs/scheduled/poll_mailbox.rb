require 'net/pop'
require_dependency 'email/receiver'
require_dependency 'email/sender'
require_dependency 'email/message_builder'

module Jobs
  class PollMailbox < Jobs::Scheduled
    every SiteSetting.pop3_polling_period_mins.minutes
    sidekiq_options retry: false

    include Email::BuildEmailHelper

    def execute(args)
      @args = args
      poll_pop3 if should_poll?
    end

    def should_poll?
      return false if Rails.env.development? && ENV["POLL_MAILBOX"].nil?
      SiteSetting.pop3_polling_enabled?
    end

    def process_popmail(popmail)
      begin
        mail_string = popmail.pop
        Email::Receiver.new(mail_string).process
      rescue => e
        handle_failure(mail_string, e)
      end
    end

    def handle_failure(mail_string, e)
      Rails.logger.warn("Email can not be processed: #{e}\n\n#{mail_string}") if SiteSetting.log_mail_processing_failures

      message_template = case e
        when Email::Receiver::EmptyEmailError             then :email_reject_empty
        when Email::Receiver::NoBodyDetectedError         then :email_reject_empty
        when Email::Receiver::NoMessageIdError            then :email_reject_no_message_id
        when Email::Receiver::AutoGeneratedEmailError     then :email_reject_auto_generated
        when Email::Receiver::InactiveUserError           then :email_reject_inactive_user
        when Email::Receiver::BadDestinationAddress       then :email_reject_bad_destination_address
        when Email::Receiver::StrangersNotAllowedError    then :email_reject_strangers_not_allowed
        when Email::Receiver::InsufficientTrustLevelError then :email_reject_insufficient_trust_level
        when Email::Receiver::ReplyUserNotMatchingError   then :email_reject_reply_user_not_matching
        when Email::Receiver::TopicNotFoundError          then :email_reject_topic_not_found
        when Email::Receiver::TopicClosedError            then :email_reject_topic_closed
        when Email::Receiver::InvalidPost                 then :email_reject_invalid_post
        when ActiveRecord::Rollback                       then :email_reject_invalid_post
        when Email::Receiver::InvalidPostAction           then :email_reject_invalid_post_action
        when Discourse::InvalidAccess                     then :email_reject_invalid_access
      end

      template_args = {}

      # there might be more information available in the exception
      if message_template == :email_reject_invalid_post && e.message.size > 6
        message_template = :email_reject_invalid_post_specified
        template_args[:post_error] = e.message
      end

      if message_template
        # inform the user about the rejection
        message = Mail::Message.new(mail_string)
        template_args[:former_title] = message.subject
        template_args[:destination] = message.to
        template_args[:site_name] = SiteSetting.title

        client_message = RejectionMailer.send_rejection(message_template, message.from, template_args)
        Email::Sender.new(client_message, message_template).send
      else
        Discourse.handle_job_exception(e, error_context(@args, "Unrecognized error type when processing incoming email", mail: mail_string))
      end
    end

    def poll_pop3
      pop3 = Net::POP3.new(SiteSetting.pop3_polling_host, SiteSetting.pop3_polling_port)
      pop3.enable_ssl if SiteSetting.pop3_polling_ssl

      pop3.start(SiteSetting.pop3_polling_username, SiteSetting.pop3_polling_password) do |pop|
        pop.delete_all do |p|
          process_popmail(p)
        end
      end
    rescue Net::POPAuthenticationError => e
      Discourse.handle_job_exception(e, error_context(@args, "Signing in to poll incoming email"))
    end

  end
end
