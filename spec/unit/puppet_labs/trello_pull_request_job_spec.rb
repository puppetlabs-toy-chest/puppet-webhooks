require 'spec_helper'
require 'puppet_labs/trello_pull_request_job'

describe PuppetLabs::TrelloPullRequestJob do
  class FakeError < StandardError; end

  let(:payload) { read_fixture("example_pull_request.json") }
  let (:pr) { PuppetLabs::PullRequest.new(:json => payload) }

  let :fake_api do
    fake_api = double(PuppetLabs::TrelloAPI)
    fake_api.stub(:create_card)
    fake_api
  end

  let :expected_card_identifier do
    "(PR #{pr.repo_name}/#{pr.number})"
  end

  let :expected_card_title do
    "#{expected_card_identifier} #{pr.title}"
  end

  subject do
    job = PuppetLabs::TrelloPullRequestJob.new
    job.pull_request = PuppetLabs::PullRequest.new(:json => payload)
    job
  end

  def github_account
    @github_account ||= {
      'name' => 'Jeff McCune',
      'email' => 'jeff@puppetlabs.com',
      'company' => 'Puppet Labs',
      'html_url' => 'https://github.com/jeffmccune',
    }
  end

  before :each do
    subject.stub(:display_card)
    subject.stub(:trello_api).and_return(fake_api)
    PuppetLabs::GithubAPI.any_instance.stub(:account).with('jeffmccune').and_return(github_account)
  end

  it 'stores a pull request' do
    subject.pull_request = pr
    subject.pull_request.should be pr
  end

  it 'produces a card body string' do
    subject.card_body.should be_a String
  end

  it 'uses the pull request info as the identifier' do
    subject.card_identifier.should == expected_card_identifier
  end

  it 'includes the card identifier in the card title' do
    subject.card_title.should match(/#{expected_card_identifier}/)
  end

  it 'includes the sender name in the title' do
    subject.card_title.should match(/Jeff McCune/)
  end

  it 'includes the sender name in the body' do
    subject.card_body.should match(/Jeff McCune/)
  end

  it 'includes the sender email in the body' do
    subject.card_body.should match(/jeff@puppetlabs.com/)
  end

  it 'includes the sender company in the body' do
    subject.card_body.should match(/Puppet Labs/)
  end

  it 'includes the sender avatar image in the body' do
    subject.card_body.should match(/!\[Jeff McCune\]\(http.*?\)/)
  end

  it 'queues the job' do
    subject.should_receive(:queue_job).with(subject, :queue => 'pull_request')
    subject.queue
  end

  describe '#find_card' do
    let(:fake_card) do
      fake_card = double(Trello::Card)
      fake_card.stub(:name).and_return(expected_card_title)
      fake_card
    end
    it 'searches all lists on the board of the list_id' do
      fake_api.should_receive(:all_cards_on_board_of).and_raise FakeError
      expect { subject.find_card(subject.card_title) }.to raise_error FakeError
    end
    it 'returns the card matching the title' do
      fake_api.should_receive(:all_cards_on_board_of).and_return([ fake_card ])
      subject.find_card(subject.card_title).should be fake_card
    end
    it 'deals with renames by identifying the card using the parens' do
      fake_api.should_receive(:all_cards_on_board_of).and_return([ fake_card ])
      id = subject.card_title.match /\(.*?\/\d+\)/
      subject.find_card("#{id} Renamed card title").should be fake_card
    end
  end

  context 'performing the task' do
    before :each do
      subject.stub(:find_card)
    end
    context 'a card does not exist' do
      it 'obtains an instance of the TrelloAPI' do
        subject.should_receive(:trello_api).and_return(fake_api)
        subject.perform
      end
      it 'creates a card on the board' do
        subject.should_receive(:create_card).and_raise FakeError
        expect { subject.perform }.to raise_error FakeError
      end
      it 'checks for the card already on the lists(s)' do
        subject.should_receive(:find_card).with(expected_card_identifier).and_raise FakeError
        expect { subject.perform }.to raise_error FakeError
      end
    end
    context 'the card does exist' do
      before :each do
        fake_card = double(Trello::Card)
        fake_card.stub(:name).and_return(expected_card_title)
        fake_card.stub(:short_id).and_return('1234')
        fake_card.stub(:url).and_return('http://trello.com/foo/bar')
        subject.stub(:find_card).and_return(fake_card)
      end
      it 'does not create the card' do
        subject.should_not_receive(:create_card)
        subject.perform
      end
    end
  end
end

describe PuppetLabs::TrelloPullRequestClosedJob do
  class FakeError < StandardError; end

  let(:payload) { read_fixture("example_pull_request_closed.json") }
  let (:pr) { PuppetLabs::PullRequest.new(:json => payload) }

  let :fake_api do
    fake_api = double(PuppetLabs::TrelloAPI)
    fake_api.stub(:create_card)
    fake_api.stub(:all_cards_on_board_of).and_return([])
    fake_api
  end

  let :expected_card_identifier do
    "(PR #{pr.repo_name}/#{pr.number})"
  end

  let :expected_card_title do
    "#{expected_card_identifier} #{pr.title}"
  end

  subject do
    job = PuppetLabs::TrelloPullRequestClosedJob.new
    job.pull_request = PuppetLabs::PullRequest.new(:json => payload)
    job
  end

  before :each do
    subject.stub(:display_card)
    subject.stub(:trello_api).and_return(fake_api)
    PuppetLabs::GithubAPI.any_instance.stub(:account).with('jeffmccune').and_return(github_account)
  end

  def github_account
    @github_account ||= {
      'name' => 'Jeff McCune',
      'email' => 'jeff@puppetlabs.com',
      'company' => 'Puppet Labs',
      'html_url' => 'https://github.com/jeffmccune',
    }
  end

  context 'performing the task' do
    let :fake_card do
      card = double(Trello::Card)
      card.stub(:name).and_return(expected_card_title)
      card.stub(:short_id).and_return('1234')
      card.stub(:url).and_return('http://trello.com/foo/bar')
      card.stub(:add_comment)
      card.stub(:closed=)
      card.stub(:save)
      card
    end

    it 'adds a comment to the card' do
      fake_card.should_receive(:add_comment).with(/closed/i)
      subject.stub(:find_card).and_return(fake_card)
      subject.perform
    end

    it 'does not archive the card if #archive_card? is false' do
      fake_card.should_not_receive(:closed=)
      subject.stub(:find_card).and_return(fake_card)
      subject.stub(:archive_card?).and_return(false)
      subject.perform
    end
    it 'archives the card if #archive_card? is true' do
      fake_card.should_receive(:closed=).with(true)
      subject.stub(:find_card).and_return(fake_card)
      subject.stub(:archive_card?).and_return(true)
      subject.perform
    end

  end
end
