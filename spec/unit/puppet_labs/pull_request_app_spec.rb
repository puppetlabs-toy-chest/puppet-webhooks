require 'spec_helper'
require 'ostruct'
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

  before :each do
    PuppetLabs::PullRequestApp.any_instance.stub(:authenticate!)
  end

  it 'says hello' do
    get '/'
    last_response.should be_ok
    last_response.body.should == "Hello World!\n"
  end

  context 'posting a pull request' do
    let (:route) { '/event/github' }
    let (:job) { PuppetLabs::PullRequestJob.new }

    describe '/event/github' do
      before :each do
        PuppetLabs::PullRequestJob.any_instance.stub(:initialize_dj)
      end

      it "responds to /event/github" do
        post route, params, env
        last_response.should have_status 202
      end

      it "saves the event" do
        PuppetLabs::PullRequestApp.any_instance.should_receive(:save_event)
        post route, params, env
        last_response.should have_status 202
      end

      it "saves the event based on STORED_EVENT_LIMIT ENV variable" do
        PuppetLabs::PullRequestApp.any_instance.should_receive(:save_event).with() do |hsh|
          hsh[:limit] == 100
        end
        post route, params, env
      end

      it "saves the event based on STORED_EVENT_LIMIT ENV variable" do
        PuppetLabs::PullRequestApp.any_instance.should_receive(:save_event).with() do |hsh|
          hsh[:limit] == 200
        end
        env_saved = ENV['STORED_EVENT_LIMIT']
        ENV['STORED_EVENT_LIMIT'] = '200'
        post route, params, env
        ENV['STORED_EVENT_LIMIT'] = env_saved
      end

      it "sets the content-type to application/json" do
        post route, params, env
        last_response.headers['Content-Type'].should == 'application/json'
      end

      it "creates a PullRequest model using PullRequest.from_json" do
        pr_model = PuppetLabs::PullRequest.new(:json => payload)
        PuppetLabs::PullRequest.should_receive(:from_json).with(payload).and_return(pr_model)
        post route, params, env
      end

      it "creates a PullRequestJob" do
        fake_job = job
        PuppetLabs::PullRequestJob.should_receive(:new).and_return(fake_job)
        post route, params, env
      end

      describe 'the return json' do
        subject do
          post route, params, env
          JSON.load(last_response.body)
        end
        it "returns a hash" do
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

      context 'posting a closed pull request' do
        let (:params) { { 'payload' => payload_closed } }

        before :each do
          fake_job = job
          pr_model = PuppetLabs::PullRequest.new(:json => payload_closed)
          PuppetLabs::PullRequest.stub(:from_json).with(payload_closed).and_return(pr_model)
          PuppetLabs::PullRequestJob.stub(:new).and_return(fake_job)
        end

        it "responds with 202" do
          post route, params, env
          last_response.should have_status 202
        end

        it "Returns a job_id key in a JSON hash" do
          post route, params, env
          JSON.load(last_response.body).should have_key "job_id"
        end
      end
    end
  end
end

describe PuppetLabs::PullRequestApp::AppHelpers do
  before :all do
    @req_yaml = read_fixture("request_struct.yml")
  end
  class TestHelpers
    include PuppetLabs::PullRequestApp::AppHelpers
  end
  subject do
    TestHelpers.new
  end
  def request
    @request ||= YAML.load(@req_yaml)
  end

  describe '.save_event' do
    [20, 30, 40].each do |event_limit|
      it "limits the number of events to #{event_limit}" do
        subject.should_receive(:limit_events_to).with(event_limit)
        subject.save_event(:request => request, :limit => event_limit)
      end
    end
  end

  describe '.limit_events_to' do
    after :each do
      PuppetLabs::Event.delete_all
    end
    event_limit = 20
    event_count = 30
    it "keeps the most recent #{event_limit} events when there are #{event_count}" do
      event_count.times do
        PuppetLabs::Event.new.save
      end
      expected = PuppetLabs::Event.order("id desc").limit(event_limit).collect do |ev|
        ev.id
      end
      subject.limit_events_to(event_limit)
      actual = PuppetLabs::Event.order("id desc").collect {|ev| ev.id }
      actual.should == expected
    end
  end
end
