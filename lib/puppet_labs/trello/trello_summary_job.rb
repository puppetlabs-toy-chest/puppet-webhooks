require 'puppet_labs/trello/base_trello_job'
require 'puppet_labs/github/pull_request'
require 'benchmark'
require 'open-uri'
require 'octokit'
require 'ostruct'
require 'liquid'

module PuppetLabs
module Trello
  ##
  # TrelloSummaryJob is responsible for performing the task of scanning each
  # card in the `TRELLO_FINISHED_LIST_ID` Trello list and extracting a summary
  # from the card commentary.  Once in possession of this information, an
  # instance of this class is able to publish the summary somewhere, e.g. a
  # Github gist.
  #
  # Instances of this object are meant to be stored with Delayed Job
class TrelloSummaryJob < BaseTrelloJob
  attr_reader :template_url

  ##
  # initialize
  #
  # @option opts [String] :template_url
  #   ('https://raw.github.com/puppetlabs/puppet-webhooks/templates/templates/trello_template.md.liquid')
  #   The template url.
  def initialize(options = {})
    @template_url = options[:template_url] || 'https://raw.github.com/puppetlabs/puppet-webhooks/templates/templates/trello_template.md.liquid'
  end

  ##
  # github provides API access to github.  Credentials are read from the
  # stored copy of the original environment.
  def github(options = {})
    options[:login] ||= env['GITHUB_ACCOUNT']
    options[:oauth_token] ||= env['GITHUB_TOKEN']
    @github ||= Octokit::Client.new(options)
  end

  ##
  # finished_list_id returns the Trello list ID for the list containing all of
  # the completed cards.  This is configured by setting the
  # `TRELLO_FINISHED_LIST_ID` environment variable.
  #
  # @api private
  def finished_list_id
    env['TRELLO_FINISHED_LIST_ID']
  end

  ##
  # finished_cards obtains all of the cards in the finished list.
  def finished_cards
    @finished_cards ||= trello_api.list_cards_in(finished_list_id)
  end

  ##
  # summary_regexp returns a regular expression that matches and extracts the
  # summary from the text of a card comment.
  def summary_regexp
    @summary_regexp ||= /^\s*summary:\s*(.*)/i
  end

  ##
  # find_summary_message searches through the comments on a card and looks for
  # a summary message matching {summary_regexp}.
  #
  # @return [String] the summary message or nil if no comment contains a
  #   message
  def find_summary_message(card)
    comments = card.actions.find_all do |action|
      action.type == 'commentCard'
    end
    if summary_comment = comments.find { |c| c.data['text'].match summary_regexp }
      mdata = summary_regexp.match(summary_comment.data['text'])
      mdata[1]
    end
  end

  ##
  # summarize_card returns a summary instance for an individual card.
  #
  # @api private
  #
  # @return [Hash] containing the card summaries
  def summarize_card(card)
    {
      'url' => card.url,
      'title' => card.name,
      'message' => find_summary_message(card) || "No comment found with `summary:`",
      'section' => find_section(card) || "Other"
    }
  end

  ##
  # find_section will return a section data structure given a card.  The card
  # labels are scanned and the first one with a `status:` prefix will be used
  # for the section name.
  #
  # @return [String] the section title or nil if the card is not labeled with
  #   any sections.
  def find_section(card)
    card.labels.detect do |label|
      if match = label.name.match(/^\s*status:\s*(.*)/i)
        return match[1]
      end
    end
  end

  ##
  # summarize will extract the summaries and produce the array of Hash
  # instances for each summarized card.
  #
  # @return [Array<OpenStruct>] containing card summaries.
  def summarize(cards)
    cards.collect do |card|
      summarize_card(card)
    end
  end

  ##
  # gist_id returns the gist ID used to publish the summary
  def gist_id
    env['GITHUB_SUMMARY_GIST_ID']
  end

  ##
  # template obtains the template for the summary.  The template is obtained
  # via URL to allow easier updates by a team of people.
  #
  # @option opts [String] :url
  #   ('https://raw.github.com/puppetlabs/puppet-webhooks/templates/templates/trello_template.md.liquid')
  #   The URL to fetch the template from.
  #
  # @return [String] the template of the summary
  def template(opts = {})
    file = opts[:file] || 'SUMMARY_TEMPLATE'
    url = opts[:url] || template_url
    # @template ||= github.gist(gist_id)['files'][file]['content']
    @template ||= open(url).read
  end

  def gist_url
    # gist = github.gist(gist_id)
    # gist.html_url
    @gist_url ||= "https://gist.github.com/#{gist_id}"
  end

  ##
  # publish_summary writes the summary content to the file named `SUMMARY.md`
  # in the gist defined by `GITHUB_SUMMARY_GIST_ID`.
  #
  # @see {Octokit::Client#edit_gist}
  #
  # @return [Hashie::Mash] the gist data from Github
  def publish_summary(content)
    update_data = { 'files' => { 'SUMMARY.md' => { 'content' => content } } }
    github.edit_gist(gist_id, update_data)
  end

  ##
  # fill_template will fill out a provided template in the current binding and
  # return the resulting string.
  #
  # @option opts [Hash] :data ('') The hash that will be passed to the Liquid
  #   engine.  The hash should contain string keys.
  #
  # @return [String] the completed template
  def fill_template(template, opts = {})
    Liquid::Template.parse(template).render(opts[:data])
  end

  def perform
    completed_cards = summarize(finished_cards)
    card_sections = completed_cards.group_by {|c| c['section'] }

    # Take advantage of Hash insertion order in 1.9 to produce a consistent
    # ordering each time.
    card_sections_ordered = {}
    card_sections.keys.sort.each do |key|
      card_sections_ordered[key] = card_sections[key]
    end

    data = {
      'cards' => completed_cards,
      'sections' => card_sections_ordered,
      'time'  => { 'now' => Time.now },
      'template' => { 'url' => template_url, 'basename' => File.basename(template_url) },
    }
    summary = fill_template(template, :data => data)

    publish_time = Benchmark.measure do
      publish_summary(summary)
    end
    display "publish_summary_time_seconds=#{publish_time.real}"
  end
end
end
end
