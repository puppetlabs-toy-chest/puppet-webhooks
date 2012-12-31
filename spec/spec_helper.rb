# figure out where we are being loaded from
if $LOADED_FEATURES.grep(/spec\/spec_helper\.rb/).any?
  begin
    raise "foo"
  rescue => e
    puts <<-MSG
  ===================================================
  It looks like spec_helper.rb has been loaded
  multiple times. Normalize the require to:

    require 'spec_helper'

  Things like File.join and File.expand_path will
  cause it to be loaded multiple times.

  Loaded this time from:

    #{e.backtrace.join("\n    ")}
  ===================================================
    MSG
  end
end

require 'rspec'
require 'active_record'
require 'rack/test'
require 'json'
require 'yaml'

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

module WebHook
module Test
module Methods
  def read_fixture(name)
    File.read(File.join(File.expand_path("..", __FILE__), "unit", "fixtures", name))
  end
end
end
end

RSpec.configure do |config|
  include WebHook::Test::Methods

  config.before :all do
    # Initialize an in-memory database
    config = {
      :adapter => 'sqlite3',
      :database => ':memory:',
    }
    ActiveRecord::Base.establish_connection(config)
    # ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Migrator.migrate("#{File.expand_path("../..", __FILE__)}/db/migrate")

  end
  config.before :suite do
    ENV['RACK_ENV'] = 'development'
  end
end
