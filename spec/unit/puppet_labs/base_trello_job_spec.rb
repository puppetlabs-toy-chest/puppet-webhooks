require 'spec_helper'
require 'puppet_labs/trello_pull_request_job'

describe PuppetLabs::BaseTrelloJob do
  subject do
    job = PuppetLabs::BaseTrelloJob.new
    job
  end

  describe '#save_settings' do
    let(:env) do
      {
        'TRELLO_APP_KEY' => 'key',
        'TRELLO_SECRET' => 'sekret',
        'TRELLO_USER_TOKEN' => 'token',
        'TRELLO_TARGET_LIST_ID' => 'list_id',
      }
    end

    before :each do
      subject.env = env
    end

    it "saves TRELLO_APP_KEY as key" do
      subject.save_settings
      subject.key.should == 'key'
    end
    it "saves TRELLO_SECRET as secret" do
      subject.save_settings
      subject.secret.should == 'sekret'
    end
    it "saves TRELLO_USER_TOKEN as token" do
      subject.save_settings
      subject.token.should == 'token'
    end
    it "saves TRELLO_TARGET_LIST_ID as list_id" do
      subject.save_settings
      subject.list_id.should == 'list_id'
    end
  end
end
