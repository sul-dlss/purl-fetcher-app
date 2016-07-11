require 'rails_helper'

describe('Fetcher lib') do
  include ApplicationHelper

  before :each do
    @fetcher = FetcherTester.new
    @fixture_data = FixtureData.new
    @earliest = '1970-01-01T00:00:00Z'
    @latest = yTenK
  end

  it 'lets us know if the user only wants registered items' do
    expect(@fetcher.registered_only?(nil)).to be false
    expect(@fetcher.registered_only?(first_modified: nil, last_modified: '01/01/2014')).to be false
    expect(@fetcher.registered_only?(status: 'registered', first_modified: nil, last_modified: '01/01/2014')).to be true
    expect(@fetcher.registered_only?(status: 'whateves', first_modified: nil, last_modified: '01/01/2014')).to be false
  end

  it 'returns the correct date range query part' do
    expect(@fetcher.get_date_solr_query(nil)).to eq("AND published_dttsim:[\"#{@earliest}\" TO \"#{@latest}\"]")
    expect(@fetcher.get_date_solr_query({})).to eq("AND published_dttsim:[\"#{@earliest}\" TO \"#{@latest}\"]")
    expect(@fetcher.get_date_solr_query(first_modified: nil, last_modified: '01/01/2014')).to eq("AND published_dttsim:[\"#{@earliest}\" TO \"2014-01-01T00:00:00Z\"]")
    expect(@fetcher.get_date_solr_query(first_modified: '01/01/2014', last_modified: nil)).to eq("AND published_dttsim:[\"2014-01-01T00:00:00Z\" TO \"#{@latest}\"]")
    expect(@fetcher.get_date_solr_query({ status: 'registered', first_modified: '01/01/2014', last_modified: nil })).to eq('')
    expect(@fetcher.get_date_solr_query(status: 'wazzup', first_modified: '01/01/2014', last_modified: nil)).to eq("AND published_dttsim:[\"2014-01-01T00:00:00Z\" TO \"#{@latest}\"]")
    expect(@fetcher.get_date_solr_query(status: 'registered')).to eq('')
  end

  it 'returns the current date and time when time not passed in' do
    expect(@fetcher.get_times(nil)).to eq(first: @earliest, last: @latest)
    expect(@fetcher.get_times({})).to eq(first: @earliest, last: @latest)
    expect(@fetcher.get_times(first_modified: nil, last_modified: '01/01/2014')).to eq(first: @earliest, last: '2014-01-01T00:00:00Z')
    expect(@fetcher.get_times(first_modified: '01/01/2014', last_modified: nil)).to eq(first: '2014-01-01T00:00:00Z', last: @latest)
  end

  it 'raises an exception if the start date is not before the end date' do
    expect{ @fetcher.get_times({ first_modified: '01/01/2010 10:00:00am', last_modified: '01/01/2009 10:00:00am' }) }.to raise_error('start time is before end time')
    expect{ @fetcher.get_times({ first_modified: '01/01/2010 10:00:00am', last_modified: '01/01/2010 10:00:00am' }) }.to raise_error('start time is before end time')
    expect{ @fetcher.get_times({ first_modified: '01/01/2010 10:00:00am', last_modified: '01/01/2010 10:00:01am' }) }.not_to raise_error
  end

  it 'raises an exception for either starting of ending date in an invalid format' do
    expect{ @fetcher.get_times(first_modified: '01/01/2010 10:00:00am', last_modified: 'ness') }.to raise_error('invalid time paramaters')
    expect{ @fetcher.get_times(first_modified: 'bogus', last_modified: '01/01/2010 10:00:00am') }.to raise_error('invalid time paramaters')
    expect{ @fetcher.get_times(first_modified: 'bogus', last_modified: 'ness') }.to raise_error('invalid time paramaters')
  end

  it 'returns the properly formatted hash for various valid types of input date or time' do
    expected = { first: '2010-01-01T10:00:00Z', last: '2011-01-01T10:00:00Z' }
    inputs = [
      { first_modified: '01/01/2010 10:00:00am',   last_modified: '01/01/2011 10:00:00am UTC' },
      { first_modified: '2010-01-01T02:00:00 PST', last_modified: '01/01/2011 2:00:00am PST' },
      { first_modified: '01/01/2010 10:00:00am',   last_modified: '2011-01-01T10:00:00Z' }
    ]
    inputs.each do |input|
      expect(@fetcher.get_times(input)).to eq(expected)
    end
    expect(@fetcher.get_times(first_modified: '01/01/2010', last_modified: '2011-01-01T18:00:00Z')).to eq(first: '2010-01-01T00:00:00Z', last: '2011-01-01T18:00:00Z')
    expect(@fetcher.get_times(first_modified: '2011-01-01T18:00:00Z', last_modified: '2014-12-01')).to eq(first: '2011-01-01T18:00:00Z', last: '2014-12-01T00:00:00Z')
    expect(@fetcher.get_times(first_modified: 'January 1, 2009', last_modified: '2012-01-01T18:00:00Z')).to eq(first: '2009-01-01T00:00:00Z', last: '2012-01-01T18:00:00Z')
  end

  it 'parses druids correctly' do
    expect(@fetcher.parse_druid('druid:oo000oo0001')).to eq('oo000oo0001')
    expect(@fetcher.parse_druid('oo000oo0001')).to eq('oo000oo0001')
    expect(@fetcher.parse_druid('bogousoo000oo0001')).to eq('oo000oo0001')
    expect{ @fetcher.parse_druid('bogus') }.to raise_error('invalid druid')
  end

  it 'adds the correct value to the solr params for counting rows' do
    solrparams = { q: { something: 'dude' }, fq: { somethingelse: 'test' } }
    default_max_row = 100_000_000
    expect(@fetcher.get_rows(solrparams, rows: 0)).to eq(solrparams.merge(rows: 0))
    expect(@fetcher.get_rows(solrparams, {})).to eq(solrparams.merge(rows: default_max_row))
    expect(@fetcher.get_rows(solrparams, othercrap: '500')).to eq(solrparams.merge(rows: default_max_row))
    expect(@fetcher.get_rows(solrparams, rows: '500')).to eq(solrparams.merge(rows: '500'))
  end

  it 'It should test for picking the proper date out of a range' do
    VCR.use_cassette('last_changed_testing') do
      latest_change = 'latest_change'
      revs_druid = @fixture_data.top_level_revs_collection_druid
      visit collection_path(revs_druid)
      response = JSON.parse(page.body)
      expect(response).to include(collections_key)
      expect(response[collections_key]).to include a_hash_including('druid' => revs_druid, 'latest_change' => '2014-06-06T05:06:06Z')
      visit collection_path(revs_druid, last_modified: '2014-06-05T05:06:06Z')
      response = JSON.parse(page.body)
      expect(response).to include(collections_key)
      expect(response[collections_key]).to include a_hash_including('druid' => revs_druid, 'latest_change' => '2014-05-05T05:04:13Z')
    end
  end

  it 'raises an error when selected for an invalid date range' do
    times = { first: yTenK, last: yTenK }
    last_changed = ['2014-05-05T05:04:13Z', '2014-04-05T05:04:13Z']
    expect{ @fetcher.determine_latest_date(times, last_changed) }.to raise_error(RuntimeError)
  end
end
