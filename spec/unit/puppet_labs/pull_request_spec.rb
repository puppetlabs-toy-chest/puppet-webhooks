require 'spec_helper'
require 'puppet_labs/pull_request'

describe 'PuppetLabs::PullRequest' do
  subject { PuppetLabs::PullRequest.new }
  let(:payload) { read_fixture("example_pull_request.json") }
  let(:data)    { JSON.load(payload) }

  it 'creates a new instance using the from_json class method' do
    pr = PuppetLabs::PullRequest.from_json(payload)
  end

  it 'initializes with json' do
    pr = PuppetLabs::PullRequest.new(:json => payload)
    pr.action.should == "opened"
  end

  describe '#load_json' do
    it 'loads a json hash readable through the data method' do
      subject.load_json(payload)
      subject.action.should == "opened"
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
    subject { PuppetLabs::PullRequest.new(:json => payload) }

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
  end
end
