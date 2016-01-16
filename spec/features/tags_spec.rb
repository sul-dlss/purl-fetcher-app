require 'rails_helper'

describe('Tags Controller') do
  before :each do
    @fetcher = FetcherTester.new
    @fixture_data = FixtureData.new
  end

  it 'should return pending for the index function' do
    VCR.use_cassette('all_tags_index_call') do
      visit tags_path
      expect(page.body).to eq(200.to_s)
    end
  end

  it 'should return zero for a tag since this is not implemented yet' do
    VCR.use_cassette('tag_foo_call') do
      visit tag_path('foo')
      expect(page.body).to eq('{"counts":{"total_count":0}}')
    end
  end
end
