require 'spec_helper'
require 'puppet_labs/sinatra_dj'

describe PuppetLabs::SinatraDJ do
  include WebHook::Test::Methods

  class FakeError < StandardError; end

  class FakeSinatraApp
    include PuppetLabs::SinatraDJ
  end

  class FakeJob
    attr_reader :accumulator

    def initialize(accumulator=[])
      @accumulator = accumulator
    end

    def perform(obj)
      @accumulator << obj
    end
  end

  let :database_yml do
    read_fixture("database.yml")
  end

  let :fake_env do
    { 'RACK_ENV' => 'development' }
  end

  let :fake_new_pull_request do
    JSON.load(read_fixture("example_pull_request.json"))
  end

  before :each do
    subject.stub(:env).and_return(fake_env)
  end

  context 'mixed into a sinatra app' do
    subject do
      FakeSinatraApp.new
    end

    describe '#queue_job' do
      let(:job) { FakeJob.new }

      it 'initializes Delayed Job' do
        subject.should_receive(:initialize_dj)
        subject.queue_job(job)
      end

      it 'returns a job with an id number' do
        subject.should_receive(:initialize_dj)
        delayed_job = subject.queue_job(job)
        delayed_job.id.should be_a Fixnum
      end

      it 'queues the job in the pull_request queue' do
        Delayed::Job.
          should_receive(:enqueue).
          with(job, :queue => 'pull_request').
          and_return(job)

        subject.queue_job(job, :queue => 'pull_request')
      end
    end

    describe '#dbconfig' do
      before :each do
        subject.stub(:read).with("config/database.yml").
          and_return(database_yml)
      end

      it "uses the read method to load the configuration" do
        subject.should_receive(:read).with("config/database.yml").and_raise(FakeError)
        expect { subject.dbconfig }.to raise_error(FakeError)
      end

      it "reads a database configuration written by Heroku" do
        hash = YAML.load(database_yml)
        dbconfig = subject.dbconfig
        dbconfig.should == hash
      end
    end

    describe '#initialize_dj' do
      let (:dbconfig) { YAML.load(database_yml) }

      before :each do
        subject.stub(:dbconfig).and_return(dbconfig)
      end

      it 'initializes the system for delayed job' do
        subject.initialize_dj
      end

      it 'uses the establish_connection method' do
        subject.should_receive(:establish_connection).
          with(dbconfig[fake_env['RACK_ENV']]).
          and_raise(FakeError)
        expect { subject.initialize_dj }.to raise_error(FakeError)
      end

      it 'establishes the database connection from config/database.yml' do
        subject.should_receive(:env).and_return(fake_env)
        subject.should_receive(:dbconfig).and_return(dbconfig)
        ActiveRecord::Base.should_receive(:establish_connection).with() do |options|
          options == dbconfig['development']
        end
        subject.initialize_dj
      end
    end
  end
end
