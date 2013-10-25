require 'puppet_labs/jira/client'
require 'puppet_labs/delayable'

module PuppetLabs
  module Jira
    class Handler
      include PuppetLabs::Delayable
    end
  end
end
