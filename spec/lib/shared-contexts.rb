shared_context "Github pull request fixture" do

  include_context "Github API fixture"

  let(:payload) { read_fixture("example_pull_request.json") }
  let(:pr) { PuppetLabs::Github::PullRequest.new(:json => payload) }

  before :each do
    allow(pr).to receive(:user).and_return(github_user)
  end
end

shared_context "Github comment fixture" do

  include_context "Github API fixture"

  let(:payload) { read_fixture("example_comment.json") }
  let(:comment) { PuppetLabs::Github::Comment.new(:json => payload) }

end

shared_context "Github API fixture" do

  def github_user
    PuppetLabs::Github::User.from_hash(github_account)
  end

  def github_account
    @github_account ||= {
      'login' => 'jeffmccune',
      'name'  => 'Jeff McCune',
      'email' => 'jeff@puppetlabs.com',
      'company' => 'Puppet Labs',
      'html_url' => 'https://github.com/jeffmccune',
      'avatar_url' => 'http://avatars.go.here',
    }
  end
end

shared_context "Jira project fixture" do

  let(:project) do
    double(PuppetLabs::Project,
      :full_name    => 'puppetlabs/puppet-webhooks',
      :jira_project => 'TEST',
      :jira_labels  => []
    )
  end
end
