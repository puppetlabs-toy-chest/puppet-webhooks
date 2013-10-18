require 'spec_helper'
require 'puppet_labs/github/pull_request'

describe 'PuppetLabs::Github::PullRequest' do
  subject { PuppetLabs::Github::PullRequest.new }
  let(:payload) { read_fixture("example_pull_request.json") }
  let(:data)    { JSON.load(payload) }

  it 'creates a new instance using the from_json class method' do
    pr = PuppetLabs::Github::PullRequest.from_json(payload)
  end

  it 'creates a new instance using the from_data class method' do
    pr = PuppetLabs::Github::PullRequest.from_data(data)
  end

  it 'initializes with json' do
    pr = PuppetLabs::Github::PullRequest.new(:json => payload)
    pr.action.should == "opened"
  end

  it 'initializes with data hash' do
    pr = PuppetLabs::Github::PullRequest.new(:data => data)
    pr.action.should == "opened"
  end

  describe '#load_json' do
    it 'loads a json hash readable through the data method' do
      subject.load_json(payload)
      subject.action.should == "opened"
    end
  end

  describe '#load_data' do
    it 'loads a ruby hash readable through the data method' do
      subject.load_data(data)
      subject.action.should == "opened"
    end

    it "doesn't raise errors if the data has no key named `sender` or `user`" do
      data['sender'] = nil
      data['user'] = nil

      expect { subject.load_data(data) }.to_not raise_error
    end
  end

  describe "#action" do
    actions = [ "opened", "closed", "synchronize" ]
    payloads = [
      read_fixture("example_pull_request.json"),
      read_fixture("example_pull_request_closed.json"),
      read_fixture("example_pull_request_synchronize.json"),
    ]

    actions.zip(payloads).each do |action, payload|
      it "returns '#{action}' when the pull request is #{action}." do
        subject.load_json(payload)
        subject.action.should == action
      end
    end
  end

  context 'newly created pull request' do
    subject { PuppetLabs::Github::PullRequest.new(:json => payload) }

    it 'has a number' do
      subject.number.should == data['pull_request']['number']
    end
    it 'has a repo name' do
      subject.repo_name.should == data['repository']['name']
    end
    it 'has a title' do
      subject.title.should == data['pull_request']['title']
    end
    it 'has a html_url' do
      subject.html_url.should == data['pull_request']['html_url']
    end
    it 'has a body' do
      subject.body.should == data['pull_request']['body']
    end
    it 'has a action' do
      subject.action.should == data['action']
    end
    it 'has a raw field' do
      subject.raw.should == data
    end
    it 'has a created_at' do
      subject.created_at.should == data['pull_request']['created_at']
    end
    it 'has a author' do
      subject.author.should == data['sender']['login']
    end
    it 'has a author_avatar_url' do
      subject.author_avatar_url.should == data['sender']['avatar_url']
    end
  end

  context 'existing pull request' do
    let(:payload) { read_fixture("example_pull_request_by_id.json") }
    subject { PuppetLabs::Github::PullRequest.new(:json => payload) }

    it 'has a number' do
      subject.number.should == data['number']
    end
    it 'has a repo name' do
      subject.repo_name.should == data['base']['repo']['name']
    end
    it 'has a title' do
      subject.title.should == data['title']
    end
    it 'has a html_url' do
      subject.html_url.should == data['html_url']
    end
    it 'has a body' do
      subject.body.should == data['body']
    end
    it 'has a action' do
      subject.action.should == "opened"
    end
    it 'has a raw field' do
      subject.raw.should == data
    end
    it 'has a created_at' do
      subject.created_at.should == data['created_at']
    end
    it 'has a author' do
      subject.author.should == data['user']['login']
    end
    it 'has a author_avatar_url' do
      subject.author_avatar_url.should == data['user']['avatar_url']
    end
  end
end
