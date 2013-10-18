shared_context "Github pull request fixture" do

  include_context "Github API fixture"

  let(:payload) { read_fixture("example_pull_request.json") }
  let (:pr) { PuppetLabs::Github::PullRequest.new(:json => payload) }

  before do
    pr.stub(:github).and_return(github_client)
  end
end

shared_context "Github comment fixture" do

  include_context "Github API fixture"

  let(:payload) { read_fixture("example_comment.json") }
  let (:comment) { PuppetLabs::Github::Comment.new(:json => payload) }

  before do
    comment.stub(:github).and_return(github_client)
  end
end

shared_context "Github API fixture" do

  def github_account
    @github_account ||= {
      'name' => 'Jeff McCune',
      'email' => 'jeff@puppetlabs.com',
      'company' => 'Puppet Labs',
      'html_url' => 'https://github.com/jeffmccune',
    }
  end

  let(:github_client) { double('PuppetLabs::Github::GithubAPI', :account => github_account) }
end
