require 'octokit'

module PuppetLabs
module Github
class GithubAPI
  attr_reader :env

  def initialize(options = {})
    options[:env] ||= ENV.to_hash
    @env = options[:env]
    @accounts = {}
  end

  def github_api(options = {})
    options[:login] ||= ENV['GITHUB_ACCOUNT']
    options[:oauth_token] ||= ENV['GITHUB_TOKEN']
    @github_api ||= Octokit::Client.new(options)
  end

  def account(login)
    @accounts[login] ||= github_api.user(login)
  end
end
end
end
