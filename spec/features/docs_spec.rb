require 'rails_helper'

# Before rerecording any tests here, make sure you've loaded the fixtures into the test solr core (or go into your solr.yml and point to the core you want to record from)
# See indexer_spec.rb test (TODO: FILL ME IN) for an example
describe('Docs Controller') do
  before(:all) do
    @fixture_path = purl_fixture_path
    @generic_end_time = '9999-01-01T00:00:00Z'
  end

  describe('Changes Response Format') do
    before(:all) do
      VCR.use_cassette('all_changes_call') do
        visit "docs/changes?last_modified=#{@generic_end_time}"
        @response = JSON.parse(page.body)
      end
    end

    it 'contains a key called changes that points to an array in the response' do
      expect(@response[:changes.to_s].class).to eq(Array)
    end

    it 'contains a changes array is made up of hashes' do
      expect(@response[:changes.to_s].size > 0).to be_truthy
      expect(@response[:changes.to_s][0].class).to eq(Hash)
    end

    it 'contains hashes in the changes array that have a key of druid that point to strings' do
      expect(@response[:changes.to_s][0][:druid.to_s].class).to eq(String)
    end

    it 'contains hashes in the changes array that have a key of latest_change that point to a string which can be parsed into a time' do
      expect(@response[:changes.to_s][0][:latest_change.to_s].class).to eq(String)
      expect(Time.parse(@response[:changes.to_s][0][:latest_change.to_s]).class).to eq(Time) # With throw exception if it cannot parse
    end

    it 'contains hashes in the changes array that have a key of true_targets and point to an array of Strings' do
      expect(@response[:changes.to_s][0][:true_targets.to_s].class).to eq(Array)
      expect(@response[:changes.to_s][0][:true_targets.to_s].size > 0).to be_truthy
      expect(@response[:changes.to_s][0][:true_targets.to_s][0].class).to eq(String)
    end

    it 'contains hashes in the changes array that have a key of false_targets and point to an array of Strings' do
      expect(@response[:changes.to_s][0][:false_targets.to_s].class).to eq(Array)
      expect(@response[:changes.to_s][0][:false_targets.to_s].size > 0).to be_truthy
      expect(@response[:changes.to_s][0][:false_targets.to_s][0].class).to eq(String)
    end
  end

  describe('Changes Response Format') do
    before(:all) do
      VCR.use_cassette('all_deletes_call') do
        visit "docs/deletes?last_modified=#{@generic_end_time}"
        @response = JSON.parse(page.body)
      end
    end

    it 'contains a key called deletes that points to an array in the response' do
      expect(@response[:deletes.to_s].class).to eq(Array)
    end

    it 'contains a deletes array is made up of hashes' do
      expect(@response[:deletes.to_s].size > 0).to be_truthy
      expect(@response[:deletes.to_s][0].class).to eq(Hash)
    end

    it 'contains hashes in the deletes array that have a key of druid that point to strings' do
      expect(@response[:deletes.to_s][0][:druid.to_s].class).to eq(String)
    end

    it 'contains hashes in the deletes array that have a key of latest_change that point to a string which can be parsed into a time' do
      expect(@response[:deletes.to_s][0][:latest_change.to_s].class).to eq(String)
      expect(Time.parse(@response[:deletes.to_s][0][:latest_change.to_s]).class).to eq(Time) # With throw exception if it cannot parse
    end
  end

  describe('Tests Show Functions') do
    before(:all) do
      VCR.use_cassette('show_call') do
        visit "docs?last_modified=#{@generic_end_time}"
        @docs_response_with_time = page.body
        visit 'docs'
        @docs_response_without_time = page.body
      end
    end

    it 'returns responses that are not JSON' do
      expect{ JSON.parse(@docs_response_with_time) }.to raise_error(JSON::ParserError)
      expect{ JSON.parse(@docs_response_without_time) }.to raise_error(JSON::ParserError)
    end

    it 'return response that are the same regardless of time params' do
      expect(@doc_response_with_time).to match(@docs_reponse_without_time)
    end
  end

  describe('Changes Response Respects Time Keys') do
  end
end
