require 'spec_helper'
require 'puppet_labs/sinatra_dj'

describe 'PuppetLabs::TrelloUtils' do
  include WebHook::Test::Methods

  subject do
    PuppetLabs::TrelloUtils
  end

  before :each do
    subject.stub(:env).and_return({
      'RACK_ENV' => 'testing'
    })
  end

  it "is a module so it works with Sinatra `helpers PuppetLabs::TrelloUtils" do
    subject.should be_a Module
  end

  context 'mixing the module in, as with Sinatra helpers PuppetLabs::TrelloUtils' do
    class FakeSinatraHelper
      include PuppetLabs::SinatraDJ
    end
    subject do
      FakeSinatraHelper.new
    end
  end
end
