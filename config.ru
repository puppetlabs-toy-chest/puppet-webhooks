$LOAD_PATH.unshift("#{File.expand_path('..', __FILE__)}/lib")

# Heroku sync for realtime logging.
STDOUT.sync = true
STDERR.sync = true

ENV['RACK_ENV'] ||= 'development'

require 'puppet_labs/pull_request_app'

run PuppetLabs::PullRequestApp
