require 'spec_helper'
require 'puppet_labs/comment'

describe 'PuppetLabs::Comment' do
  subject { PuppetLabs::Comment.new }
  let(:payload) { read_fixture("example_comment.json") }
  let(:data)    { JSON.load(payload) }

  it 'creates a new instance using the from_json class method' do
    PuppetLabs::Comment.from_json(payload)
  end

  it 'initializes with json' do
    comment = PuppetLabs::Comment.new(:json => payload)
    comment.action.should == "created"
  end

  describe '#load_json' do
    it 'loads a json hash readable through the data method' do
      subject.load_json(payload)
      subject.action.should == "created"
    end
  end

  describe "#action" do
    actions = [ "created" ]
    payloads = [
      read_fixture("example_comment.json")
    ]

    actions.zip(payloads).each do |action, payload|
      it "returns '#{action}' when the issue is #{action}." do
        subject.load_json(payload)
        subject.action.should == action
      end
    end
  end

  describe "#issue" do
    subject { PuppetLabs::Comment.new(:json => payload) }

    it 'is an instance of PuppetLabs::Issue' do
      expect(subject.issue.instance_of?(PuppetLabs::Issue)).to be
    end
  end

  describe "#pull_request" do
    subject { PuppetLabs::Comment.new(:json => payload) }

    it 'is an instance of PuppetLabs::PullRequest' do
      expect(subject.pull_request.instance_of?(PuppetLabs::PullRequest)).to be
    end
  end

  describe "#repo_name" do
    subject { PuppetLabs::Comment.new(:json => payload) }

    it 'delegates from the issue' do
      expect(subject.repo_name).to eq subject.issue.repo_name
    end
  end

  context 'newly created comment' do
    subject { PuppetLabs::Comment.new(:json => payload) }

    it 'has a body' do
      subject.body.should == data['comment']['body']
    end

    it 'has an author login' do
      subject.author_login.should == data['sender']['login']
    end

    it 'has an author avatar url' do
      subject.author_avatar_url.should == data['sender']['avatar_url']
    end
  end
end
