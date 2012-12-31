require 'spec_helper'
require 'puppet_labs/pull_request_app'

describe 'PuppetLabs::PullRequestApp' do
  include Rack::Test::Methods

  def app
    PuppetLabs::PullRequestApp
  end

  attr_reader :payload, :params

  before :all do
    @payload = read_fixture("example_pull_request.json")
    @params = { 'payload' => @payload }
  end

  it 'says hello' do
    get '/'
    last_response.should be_ok
    last_response.body.should == "Hello World!"
  end

  context 'posting a pull request' do
    describe '/event/pull_request' do
      let (:route) { '/event/pull_request' }
      let (:pr_model) { PuppetLabs::PullRequest.new(:json => payload) }
      let (:job) { PuppetLabs::PullRequestJob.new }

      before :each do
        fake_job = job
        PuppetLabs::PullRequest.stub(:from_json).with(payload).and_return(pr_model)
        PuppetLabs::PullRequestJob.stub(:new).and_return(fake_job)
      end

      it "responds to /event/pull_request" do
        post route, params
        last_response.status.should == 202
      end

      it "sets the content-type to application/json" do
        post route, params
        last_response.headers['Content-Type'].should == 'application/json'
      end

      describe 'the return json' do
        subject do
          post route, params
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
        post route, params
      end

      it "creates a PullRequestJob" do
        PuppetLabs::PullRequestJob.should_receive(:new).and_return(job)
        post route, params
      end

      it "adds the pull request data to the job" do
        post route, params
        job.pull_request.should eq(pr_model)
      end

      it "queues the job" do
        job.should_receive(:queue)
        post route, params
      end
    end
  end
end
