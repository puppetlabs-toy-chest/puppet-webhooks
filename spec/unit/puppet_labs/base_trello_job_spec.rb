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
        'ARCHIVE_CARD' => 'true',
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
    it "saves ARCHIVE_CARD to enable #archive_card?" do
      subject.save_settings
      subject.archive_card?.should be_true
    end
  end

  describe '#archive_card?' do
    it 'is false by default' do
      subject.save_settings
      subject.archive_card?.should be_false
    end
    it 'is false if ARCHIVE_CARD is empty' do
      subject.env = { 'ARCHIVE_CARD' => '' }
      subject.save_settings
      subject.archive_card?.should be_false
    end
    it 'is false if ARCHIVE_CARD is garbage' do
      subject.env = { 'ARCHIVE_CARD' => 'asdfasdf' }
      subject.save_settings
      subject.archive_card?.should be_false
    end
    it 'is true if ARCHIVE_CARD is TRUE' do
      subject.env = { 'ARCHIVE_CARD' => 'TRUE' }
      subject.save_settings
      subject.archive_card?.should be_true
    end
    it 'is true if ARCHIVE_CARD is true' do
      subject.env = { 'ARCHIVE_CARD' => 'true' }
      subject.save_settings
      subject.archive_card?.should be_true
    end
    it 'is true if ARCHIVE_CARD is YES' do
      subject.env = { 'ARCHIVE_CARD' => 'YES' }
      subject.save_settings
      subject.archive_card?.should be_true
    end
    it 'is true if ARCHIVE_CARD is yes' do
      subject.env = { 'ARCHIVE_CARD' => 'yes' }
      subject.save_settings
      subject.archive_card?.should be_true
    end
    it 'is false if ARCHIVE_CARD is YESnoYES' do
      subject.env = { 'ARCHIVE_CARD' => 'YESnoYES' }
      subject.save_settings
      subject.archive_card?.should be_false
    end
    it 'is false if ARCHIVE_CARD is TRUEnoTRUE' do
      subject.env = { 'ARCHIVE_CARD' => 'TRUEnoTRUE' }
      subject.save_settings
      subject.archive_card?.should be_false
    end
  end
end
