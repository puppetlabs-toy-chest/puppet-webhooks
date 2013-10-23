$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'rake'
require 'gepetto_hooks'
require 'benchmark'
require 'erb'
require 'sinatra/activerecord/rake'
require 'puppet_labs/pull_request_app'
require 'delayed/tasks'
require 'puppet_labs/webhook'
require 'rest_client'

if not ENV['RACK_ENV']
  ENV['RACK_ENV'] ||= 'test'
end

task :default => :help

desc 'List tasks (rake -T)'
task :help do
  sh 'rake -T'
end

# Setup the environment for the application
task :environment do
  PuppetLabs::Webhook.setup_environment(ENV['RACK_ENV'])
end

desc "IRB REPL Shell"
task :shell => :environment do
  require 'irb'
  ARGV.clear
  IRB.start
end

task :pry => :environment do
  require 'pry'
  binding.pry
end


namespace :db do
  namespace :pg do
    desc "Create the database"
    task :create => :environment do
      ar_dbconfig = PuppetLabs::Webhook.dbconfig(ENV['RACK_ENV'])

      # drop the old database if it exists
      ActiveRecord::Base.connection.drop_database ar_dbconfig['database']
      ActiveRecord::Base.connection.create_database ar_dbconfig['database']
      puts "Created empty database #{ar_dbconfig['database']}"
    end
  end

  desc "Migrate the database"
  task :migrate => :environment do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
  end
end

namespace :api do
  desc "Run the server using foreman form the Heroku toolbelt"
  task :run do
    sh 'foreman start'
  end

  desc "Submit a fake pull request"
  task(:pull_request) do
    sh 'curl -i -H "Content-Type: application/json" --data "$(cat spec/unit/fixtures/example_pull_request.json)" http://localhost:5000/event/github/'
  end

  desc "Submit a fake issue"
  task(:issue) do
    sh 'curl -i -H "Content-Type: application/json" --data "$(cat spec/unit/fixtures/example_issue.json)" http://localhost:5000/event/github/'
  end
end

desc "Use watchr to auto test"
task :watchr do
  sh 'bundle exec watchr spec/watchr.rb'
end

desc "Run a web server with documentation"
task :apidoc do
  sh 'bundle exec yard server --reload'
end

namespace :jobs do
  desc "Run a delayed job worker quietly"
  task :worksilent => :environment do
    Delayed::Worker.new(:min_priority => ENV['MIN_PRIORITY'],
                        :max_priority => ENV['MAX_PRIORITY'],
                        :queues => (ENV['QUEUES'] || ENV['QUEUE'] || '').split(','),
                        :quiet => true).start
  end

  desc "Update the finished card summary (uses GITHUB_SUMMARY_GIST_ID,TRELLO_FINISHED_LIST_ID,SUMMARY_TEMPLATE_URL)"
  task :summary => :environment do
    puts "Summarizing completed cards..."
    job = PuppetLabs::Trello::TrelloSummaryJob.new(:template_url => ENV['SUMMARY_TEMPLATE_URL'])
    summary_time = Benchmark.measure do
      job.perform
    end
    puts "summary_time_seconds=#{summary_time.real}"
    puts "gist_url=#{job.gist_url}"
  end
end

namespace :import do
  desc "Import existing PRs from a GitHub repo (use REPO=puppetlabs/puppet, optionally PR=123)"
  task :prs => :environment do

    url = "https://api.github.com/repos/#{ENV['REPO']}/pulls"
    url << '/' << ENV['PR'] if ENV['PR']
    resource = RestClient::Resource.new(url, :user => ENV['GITHUB_ACCOUNT'], :password => ENV['GITHUB_TOKEN'])
    response = JSON.parse(resource.get)
    response = [response] if ENV['PR']
    response.reverse.each do |pr|
      queued = PuppetLabs::Github::PullRequestController.new(:pull_request => PuppetLabs::Github::PullRequest.from_data(pr)).run
      raise StandardError, "Failed to queue PR##{pr.number}: #{queued.inspect}" unless queued[0].to_s[0] == '2'
    end
  end
end

desc "Run the examples in spec/"
task :spec do
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
end
