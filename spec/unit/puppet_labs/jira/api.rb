require 'spec_helper'
require 'puppet_labs/jira/api'

describe PuppetLabs::Jira::API do

  let(:stub_env) do
    {
      'JIRA_USERNAME' => 'user',
      'JIRA_PASSWORD' => 'pass',
      'JIRA_SITE'     => 'http://site.blackhole:3145',
      'JIRA_CONTEXT_PATH' => '/context'
    }
  end

  describe 'using environment variables for configuration' do

    %w[
      JIRA_USERNAME
      JIRA_PASSWORD
      JIRA_SITE
      JIRA_CONTEXT_PATH
    ].each do |var|
      it "requires #{var} to be set" do
        stub_env.delete var

        expect {
          described_class.env_api_options(stub_env)
        }.to raise_error PuppetLabs::Jira::API::EmptyVariableError, /missing.*#{var}/
      end
    end

    it "returns a hash if all required variables are set" do
      expect(described_class.env_api_options(stub_env)).to be_a_kind_of Hash
    end
  end
end
