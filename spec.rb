require 'rspec'
require 'rack/test'
require_relative './web.rb'

set :environment, :test

describe 'The Puppet Webhook App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "says hello" do
    get "/"
    last_response.should be_ok
    last_response.body.should == 'Hello World'
  end
end
