require 'spec_helper'
require 'puppet_labs/issue'

describe 'PuppetLabs::Issue' do
  subject { PuppetLabs::Issue.new }
  let(:payload) { read_fixture("example_issue.json") }
  let(:data)    { JSON.load(payload) }

  it 'creates a new instance using the from_json class method' do
    pr = PuppetLabs::Issue.from_json(payload)
  end

  it 'initializes with json' do
    pr = PuppetLabs::Issue.new(:json => payload)
    pr.action.should == "opened"
  end

  describe '#load_json' do
    it 'loads a json hash readable through the data method' do
      subject.load_json(payload)
      subject.action.should == "opened"
    end
  end

  describe "#action" do
    actions = [ "opened", "closed", "reopened" ]
    payloads = [
      read_fixture("example_issue.json"),
      read_fixture("example_issue_closed.json"),
      read_fixture("example_issue_reopened.json"),
    ]

    actions.zip(payloads).each do |action, payload|
      it "returns '#{action}' when the issue is #{action}." do
        subject.load_json(payload)
        subject.action.should == action
      end
    end
  end

  describe '#pull_request' do
    subject { PuppetLabs::Issue.new(:json => payload) }

    it "is an instance of PuppetLabs::PullRequest" do
      expect(subject.pull_request.instance_of?(PuppetLabs::PullRequest)).to be
    end
  end

  context 'newly created issue' do
    subject { PuppetLabs::Issue.new(:json => payload) }

    it 'has a number' do
      subject.number.should == data['issue']['number']
    end
    it 'has a repo name' do
      subject.repo_name.should == data['repository']['name']
    end
    it 'has a title' do
      subject.title.should == data['issue']['title']
    end
    it 'has a html_url' do
      subject.html_url.should == data['issue']['html_url']
    end
    it 'has a body' do
      subject.body.should == data['issue']['body']
    end
  end
end
