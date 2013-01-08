require 'spec_helper'
require 'puppet_labs/pull_request_app'

describe 'PuppetLabs::PullRequestApp' do
  include Rack::Test::Methods

  def app
    PuppetLabs::PullRequestApp
  end

  attr_reader :payload,
    :params,
    :env,
    :payload_closed,
    :payload_synchronize

  before :all do
    @payload = read_fixture("example_pull_request.json")
    @payload_closed = read_fixture("example_pull_request_closed.json")
    @payload_synchronize = read_fixture("example_pull_request_synchronize.json")
    @params = { 'payload' => @payload }
    @env = { 'HTTP_X_GITHUB_EVENT' => 'pull_request' }
  end

  it 'says hello' do
    get '/'
    last_response.should be_ok
    last_response.body.should == "Hello World!"
  end

  context 'posting a pull request' do
    let (:route) { '/event/github' }
    let (:job) { PuppetLabs::PullRequestJob.new }

    describe '/event/github' do
      let (:pr_model) { PuppetLabs::PullRequest.new(:json => payload) }

      before :each do
        PuppetLabs::PullRequestJob.any_instance.stub(:initialize_dj)
      end

      it "responds to /event/github" do
        post route, params, env
        last_response.status.should == 202
      end

      it "sets the content-type to application/json" do
        post route, params, env
        last_response.headers['Content-Type'].should == 'application/json'
      end

      describe 'the return json' do
        subject do
          post route, params, env
          JSON.load(last_response.body)
        end
        it "returns a json hash" do
          subject.should be_a Hash
        end

        it 'contains a job_id key with a Fixnum value' do
          subject['job_id'].should be_a Fixnum
        end

        it 'contains a queue key with a String value' do
          subject['queue'].should be_a String
        end

        it 'contains a priority key with a Fixnum value' do
          subject['priority'].should be_a Fixnum
        end

        it 'contains a created_at key that works with Time.parse' do
          expect { Time.parse(subject['created_at']) }.not_to raise_error
        end
      end

      it "creates a PullRequest model using PullRequest.from_json" do
        PuppetLabs::PullRequest.should_receive(:from_json).with(payload).and_return(pr_model)
        post route, params, env
      end

      it "creates a PullRequestJob" do
        fake_job = job
        PuppetLabs::PullRequestJob.should_receive(:new).and_return(fake_job)
        post route, params, env
      end
    end

    context 'posting a closed pull request' do
      let (:params) { { 'payload' => payload_closed } }
      let (:pr_model) { PuppetLabs::PullRequest.new(:json => payload_closed) }

      before :each do
        fake_job = job
        PuppetLabs::PullRequest.stub(:from_json).with(payload_closed).and_return(pr_model)
        PuppetLabs::PullRequestJob.stub(:new).and_return(fake_job)
      end

      it "responds with 200 to /event/pull_request" do
        post route, params, env
        last_response.status.should == 200
      end

      it "Says 'Action has been ignored.' in the response body." do
        post route, params, env
        JSON.load(last_response.body)['message'].should == 'Action has been ignored.'
      end
    end
  end
end
