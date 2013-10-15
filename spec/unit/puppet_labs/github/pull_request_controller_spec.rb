require 'spec_helper'
require 'puppet_labs/github/pull_request_controller'

describe PuppetLabs::Github::PullRequestController do

  let(:payload)      { read_fixture("example_pull_request.json") }
  let(:pull_request) { PuppetLabs::Github::PullRequest.new(:json => payload) }

  let(:logger)  { double('logger').as_null_object }
  let(:route)   { double('sinatra app') }
  let(:request) { double('http request') }


  let(:controller_options) do
    {
      :logger  => logger,
      :route   => route,
      :request => request,
      :pull_request => pull_request,
    }
  end

  subject { described_class.new(controller_options) }

  describe 'with no event outputs' do
    before { subject.outputs = [] }

    it "has an empty list of event outputs" do
      body = subject.run.last
      expect(body['outputs']).to be_a_kind_of Array
      expect(body['outputs']).to be_empty
    end

    it "only has the list of outputs" do
      body = subject.run.last
      expect(body['outputs']).to be_a_kind_of Array
      expect(body['outputs']).to be_empty
    end
  end

  shared_examples_for "a supported event handler" do |name|

    it "creates a delayed job for the #{name} handler" do
      expect(handler).to receive(:queue).and_return delayed_job
      subject.run
    end

    it "adds the #{name} delayed job information to the response" do
      allow(handler).to receive(:queue).and_return delayed_job
      body = subject.run.last
      expect(body[name]['status']).to eq delayed_job.status
      expect(body[name]['job_id']).to eq delayed_job.id
      expect(body[name]['queue']).to eq  delayed_job.queue
      expect(body[name]['priority']).to eq delayed_job.priority
      expect(body[name]['created_at']).to eq delayed_job.created_at
    end
  end

  describe 'with the jira event output' do
    before do
      subject.outputs = %w[jira]
      allow(PuppetLabs::Jira::PullRequestHandler).to receive(:new).and_return handler
    end

    let(:handler) { double('jira pull request handler', :pull_request= => nil) }
    let(:delayed_job)  { double('delayed job', :status => 'ok', :id => 42, :queue => 'Q', :priority => 'very yes', :created_at => 'date') }

    it_behaves_like "a supported event handler", 'jira'
  end

  describe 'with the trello event output' do
    before do
      subject.outputs = %w[trello]
      allow(PuppetLabs::Trello::TrelloPullRequestJob).to receive(:new).and_return handler
    end

    let(:handler) { double('trello pull request handler', :pull_request= => nil) }
    let(:delayed_job)  { double('delayed job', :status => 'ok', :id => 42, :queue => 'Q', :priority => 'very yes', :created_at => 'date') }

    it_behaves_like "a supported event handler", 'trello'
  end

  describe 'with both jira and trello event outputs' do
    let(:trello_handler) { double('trello pull request handler', :pull_request= => nil) }
    let(:jira_handler) { double('jira pull request handler', :pull_request= => nil) }

    let(:delayed_job)  { double('delayed job', :status => 'ok', :id => 42, :queue => 'Q', :priority => 'very yes', :created_at => 'date') }

    before do
      subject.outputs = %w[trello jira]
      allow(PuppetLabs::Trello::TrelloPullRequestJob).to receive(:new).and_return trello_handler
      allow(PuppetLabs::Jira::PullRequestHandler).to receive(:new).and_return jira_handler

      allow(jira_handler).to receive(:queue).and_return delayed_job
      allow(trello_handler).to receive(:queue).and_return delayed_job
    end

    it "includes both outputs" do
      body = subject.run.last
      expect(body['outputs']).to include 'jira'
      expect(body['outputs']).to include 'trello'
    end

    it "includes messages from both outputs" do
      body = subject.run.last
      expect(body).to have_key 'jira'
      expect(body).to have_key 'trello'
    end
  end
end
