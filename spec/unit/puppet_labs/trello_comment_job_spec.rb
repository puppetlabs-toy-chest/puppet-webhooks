require 'spec_helper'
require 'puppet_labs/trello_comment_job'

describe PuppetLabs::TrelloCommentJob do
  class FakeError < StandardError; end

  let(:payload) { read_fixture("example_comment.json") }
  let (:comment) { PuppetLabs::Comment.new(:json => payload) }

  let :fake_api do
    fake_api = double(PuppetLabs::TrelloAPI)
    fake_api.stub(:create_card)
    fake_api
  end

  let :expected_card_title do
    "#{expected_card_identifier} #{comment.issue.title}"
  end

  subject do
    job = PuppetLabs::TrelloCommentJob.new
    job.comment = comment
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

  it 'stores a comment' do
    subject.comment = comment
    subject.comment.should be comment
  end

  it 'produces a card body string' do
    subject.card_body.should be_a String
  end

  it 'includes the card identifier in the card title' do
    subject.card_title.should match(/#{subject.card_identifier}/)
  end

  it 'includes the comment in the body' do
    subject.card_body.should match(Regexp.new(comment.body))
  end

  it 'includes the sender username in the body' do
    # We don't have access to the full name in GitHub's issue_comment events.
    # See spec/unit/fixtures/example_comment.json for the full response.
    # We will use the `login` instead, since that is provided.
    subject.card_body.should match(Regexp.new(comment.author_login))
  end

  it 'queues the job' do
    subject.should_receive(:queue_job).with(subject, :queue => 'comment')
    subject.queue
  end

  describe "#card_subidentifier" do
    context 'comment was on a pull request' do
      before :each do
        subject.comment.stub(:pull_request?).and_return(true)
      end

      it 'returns the PR identifier' do
        expect(subject.card_subidentifier).to eq 'PR'
      end
    end

    context 'comment was on a issue' do
      before :each do
        subject.comment.stub(:pull_request?).and_return(false)
      end

      it 'returns the GH-ISSUE identifier' do
        expect(subject.card_subidentifier).to eq 'GH-ISSUE'
      end
    end
  end

  context 'performing the task' do
    let :fake_card do
      card = double(Trello::Card)
      card.stub(:name).and_return(subject.card_title)
      card.stub(:short_id).and_return('1234')
      card.stub(:url).and_return('http://trello.com/foo/bar')
      card.stub(:add_comment)
      card.stub(:closed=)
      card.stub(:save)
      card
    end

    it 'adds a comment to the card' do
      fake_card.should_receive(:add_comment).with(subject.card_body)
      subject.stub(:find_card).and_return(fake_card)
      subject.perform
    end
  end
end
