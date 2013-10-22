require 'sinatra/activerecord'
require 'active_record/base'

module PuppetLabs

  # This class provides a central place to store data about projects.
  class Project < ActiveRecord::Base

    # @!attribute full_name

    validates_uniqueness_of :full_name

    # @!attribute jira_project

    validates :jira_project, :allow_blank => true,
      :format => { :with => %r/[A-Z][A-Z0-9_]*/ }

    # @!attribute jira_labels

    serialize :jira_labels, Array
  end
end
