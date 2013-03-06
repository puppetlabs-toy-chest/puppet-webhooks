require 'puppet_labs/github_api'

module PuppetLabs
module GithubMix
  def github
    @github ||= PuppetLabs::GithubAPI.new(:env => env)
  end

  def author_name
    account = author
    if name = github.account(account)['name'] and not name.empty?
      name
    else
      account
    end
  end

  def author_email
    github.account(author)['email']
  end

  def author_company
    github.account(author)['company']
  end

  def author_html_url
    github.account(author)['html_url']
  end
end
end
