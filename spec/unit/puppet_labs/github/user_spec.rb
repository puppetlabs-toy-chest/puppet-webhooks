require 'spec_helper'
require 'puppet_labs/github/user'

describe PuppetLabs::Github::User do

  describe "fetched from the github /users endpoint" do
    let(:json)      { read_fixture('example_user.json') }
    let(:user_data) { json }

    subject { described_class.from_hash(user_data) }

    it "has a login" do
      expect(subject.login).to eq user_data['login']
    end

    it "has a html url" do
      expect(subject.html_url).to eq user_data['html_url']
    end

    it "has an avatar url" do
      expect(subject.avatar_url).to eq user_data['avatar_url']
    end

    it "has a company" do
      expect(subject.company).to eq user_data['company']
    end

    it "has a full name" do
      expect(subject.name).to eq user_data['name']
    end

    it "has an email address" do
      expect(subject.email).to eq user_data['email']
    end
  end

  describe "extracted from another entity" do
    let(:json) { read_fixture('example_issue.json') }
    let(:user_data) { json['sender'] }

    let(:client) { double('Octokit::Client') }

    let(:response) do
      {
        'name'    => 'Jimmy',
        'company' => 'Acme',
        'email'   => 'jimmy@acme.com',
      }
    end

    subject { described_class.from_hash(user_data) }

    before do
      subject.client = client
      allow(client).to receive(:user).with(subject.login).and_return(response)
    end

    it "can fetch the user company" do
      expect(subject).to receive(:fetch!).and_call_original
      expect(subject.company).to eq 'Acme'
    end

    it "can fetch the user full name" do
      expect(subject).to receive(:fetch!).and_call_original
      expect(subject.name).to eq 'Jimmy'
    end

    it "can fetch the user email address" do
      expect(subject).to receive(:fetch!).and_call_original
      expect(subject.email).to eq 'jimmy@acme.com'
    end

    it "eagerly populates all fields" do
      expect(subject).to receive(:fetch!).and_call_original.at_most(:once)

      expect(subject.name).to eq 'Jimmy'
      expect(subject.email).to eq 'jimmy@acme.com'


    end
  end
end
