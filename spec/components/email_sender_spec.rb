require 'spec_helper'
require 'email_sender'

describe EmailSender do

  it "doesn't deliver mail when the message is nil" do
    Mail::Message.any_instance.expects(:deliver).never
    EmailSender.new(nil, :hello).send
  end

  it "doesn't deliver when the to address is nil" do
    message = Mail::Message.new(body: 'hello')
    message.expects(:deliver).never
    EmailSender.new(message, :hello).send
  end

  it "doesn't deliver when the body is nil" do
    message = Mail::Message.new(to: 'eviltrout@test.domain')
    message.expects(:deliver).never
    EmailSender.new(message, :hello).send
  end

  context 'with a valid message' do

    let(:message) do
      message = Mail::Message.new to: 'eviltrout@test.domain',
                                  body: '**hello**'
      message.stubs(:deliver)
      message
    end

    let(:email_sender) { EmailSender.new(message, :valid_type) }

    it 'calls deliver' do
      message.expects(:deliver).once
      email_sender.send
    end

    context 'email logs' do

      before do
        email_sender.send
        @email_log = EmailLog.last
      end

      it 'creates an email log' do
        @email_log.should be_present
      end

      it 'has the correct type' do
        @email_log.email_type.should == 'valid_type'
      end

      it 'has the correct to_address' do
        @email_log.to_address.should == 'eviltrout@test.domain'
      end

      it 'has no user_id' do
        @email_log.user_id.should be_blank
      end


    end

    context 'email parts' do
      before { email_sender.send }

      it 'makes the message multipart' do
        message.should be_multipart
      end

      it 'sets the correct content type for the plain text part' do
        expect(message.text_part.content_type).to eq 'text/plain; charset=UTF-8'
      end

      it 'sets the correct content type for the html part' do
        expect(message.html_part.content_type).to eq 'text/html; charset=UTF-8'
      end

      it 'converts the html part to html' do
        expect(message.html_part.body.to_s).to match("<p><strong>hello</strong></p>")
      end
    end
  end

  context 'with a user' do
    let(:message) do
      message = Mail::Message.new to: 'eviltrout@test.domain', body: 'test body'
      message.stubs(:deliver)
      message
    end

    let(:user) { Fabricate(:user) }
    let(:email_sender) { EmailSender.new(message, :valid_type, user) }

    before do
      email_sender.send
      @email_log = EmailLog.last
    end

    it 'should have the current user_id' do
      @email_log.user_id.should == user.id
    end


  end

end
