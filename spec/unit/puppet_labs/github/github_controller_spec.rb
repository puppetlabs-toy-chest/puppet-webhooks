require 'spec_helper'
require 'puppet_labs/github/github_controller'

describe PuppetLabs::Github::GithubController do

  let(:logger)  { double('logger').as_null_object }
  let(:route)   { double('sinatra app') }
  let(:request) { double('http request') }


  let(:controller_options) do
    {
      :logger  => logger,
      :route   => route,
      :request => request,
    }
  end

  subject { PuppetLabs::Github::GithubController.new(controller_options) }


  before :each do
    allow(subject).to receive(:logger).and_return logger
  end

  describe 'handling a pull request event' do
    before do
      allow(request).to receive(:env).and_return(double('request env', :[] => 'pull_request'))
      allow(route).to receive(:payload).and_return(read_fixture("example_pull_request.json"))
    end

    it "creates a Github Pull Request controller" do
      expect(subject.event_controller).to be_a_kind_of PuppetLabs::Github::PullRequestController
    end
  end

  describe 'handling an issue event' do
    before do
      allow(request).to receive(:env).and_return(double('request env', :[] => 'issues'))
      allow(route).to receive(:payload).and_return(read_fixture("example_issue.json"))
    end

    it "creates a Github Issue controller" do
      expect(subject.event_controller).to be_a_kind_of PuppetLabs::Github::IssueController
    end
  end

  describe 'handling an issue_comment event' do
    before do
      allow(request).to receive(:env).and_return(double('request env', :[] => 'issue_comment'))
      allow(route).to receive(:payload).and_return(read_fixture("example_comment.json"))
    end

    it "creates a Github Comment controller" do
      expect(subject.event_controller).to be_a_kind_of PuppetLabs::Github::CommentController
    end
  end

  describe 'handling an unrecognized event' do
    before do
      allow(request).to receive(:env).and_return(double('request env', :[] => 'oh_god_the_bees'))
    end

    it "logs a message that the event was unhandled" do
      expect(logger).to receive(:info) do |arg|
        expect(arg).to match /Ignoring.*oh_god_the_bees/
      end
      subject.event_controller
    end

    it "doesn't generate a controller" do
      expect(subject.event_controller).to be_nil
    end
  end
end
