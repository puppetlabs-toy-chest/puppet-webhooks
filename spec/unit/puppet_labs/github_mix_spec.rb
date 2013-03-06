require 'spec_helper'
require 'puppet_labs/github_mix'

describe "PuppetLabs::GithubMix mixin" do
  class FakeJob
    include PuppetLabs::GithubMix
    def author
      @author ||= 'jeffmccune'
    end
  end
  subject { FakeJob.new }

  context 'complete account information' do
    let(:account) do
      {
        'name' => 'Jeff McCune',
        'email' => 'jeff@puppetlabs.com',
        'company' => 'Puppet Labs',
        'html_url' => 'https://github.com/jeffmccune',
      }
    end
    let(:github) do
      github = double('GithubAPI', :account => account)
    end
    before :each do
      subject.stub(:github).and_return(github)
    end

    it 'uses the github API to retrieve the author name' do
      subject.author_name.should == 'Jeff McCune'
    end
    it 'uses the github API to retrieve the author email' do
      subject.author_email.should == 'jeff@puppetlabs.com'
    end
    it 'uses the github API to retrieve the author company' do
      subject.author_company.should == 'Puppet Labs'
    end
    it 'uses the github API to retrieve the author account URL' do
      subject.author_html_url.should == 'https://github.com/jeffmccune'
    end
  end

  context 'incomplete account information' do
    let(:account) do
      {
        'html_url' => 'https://github.com/jeffmccune',
      }
    end
    let(:github) do
      github = double('GithubAPI', :account => account)
    end
    before :each do
      subject.stub(:github).and_return(github)
    end

    it 'uses the account name if the user name is nil' do
      subject.author_name.should == 'jeffmccune'
    end
    it 'uses the account name if the user name is empty' do
      github = double('GithubAPI', :account => account.merge('name' => ''))
      subject.stub(:github).and_return(github)
      subject.author_name.should == 'jeffmccune'
    end
  end
end
