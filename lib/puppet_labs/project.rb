require 'sinatra/activerecord'
require 'active_record/base'

module PuppetLabs

  # This class provides a central place to store data about projects.
  class Project < ActiveRecord::Base

    # @!attribute full_name
    #   @return [String] The github repository full name
    #   @example
    #     project.full_name #=> "puppetlabs/puppet-webhooks"

    validates_uniqueness_of :full_name

    # @!attribute jira_project
    #   @return [String] The Jira project key
    #   @example
    #     project.jira_project #=> "PWH"

    validates :jira_project, :allow_blank => true,
      :format => { :with => %r/[A-Z][A-Z0-9_]*/ }

    # @!attribute jira_labels
    #   @return [Array<String>] A list of labels to apply to the Jira issue
    #   @example
    #     project.jira_labels #=> ["github", "webhook"]

    serialize :jira_labels, Array
  end
end
