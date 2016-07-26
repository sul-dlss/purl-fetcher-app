require 'rails_helper'

describe('Fetcher lib') do
  let(:fetcher) { FetcherTester.new }
  let(:earliest) { '1970-01-01T00:00:00Z' }
  let(:latest) { ModificationTime::Y_TEN_K }

  it 'lets us know if the user only wants registered items' do
    expect(fetcher.registered_only?(nil)).to be false
    expect(fetcher.registered_only?(first_modified: nil, last_modified: '01/01/2014')).to be false
    expect(fetcher.registered_only?(status: 'registered', first_modified: nil, last_modified: '01/01/2014')).to be true
    expect(fetcher.registered_only?(status: 'whateves', first_modified: nil, last_modified: '01/01/2014')).to be false
  end

  it 'returns the correct date range query part' do
    expect(fetcher.get_date_solr_query(nil)).to eq("AND published_dttsim:[\"#{earliest}\" TO \"#{latest}\"]")
    expect(fetcher.get_date_solr_query({})).to eq("AND published_dttsim:[\"#{earliest}\" TO \"#{latest}\"]")
    expect(fetcher.get_date_solr_query(first_modified: nil, last_modified: '01/01/2014')).to eq("AND published_dttsim:[\"#{earliest}\" TO \"2014-01-01T00:00:00Z\"]")
    expect(fetcher.get_date_solr_query(first_modified: '01/01/2014', last_modified: nil)).to eq("AND published_dttsim:[\"2014-01-01T00:00:00Z\" TO \"#{latest}\"]")
    expect(fetcher.get_date_solr_query(status: 'registered', first_modified: '01/01/2014', last_modified: nil)).to eq('')
    expect(fetcher.get_date_solr_query(status: 'wazzup', first_modified: '01/01/2014', last_modified: nil)).to eq("AND published_dttsim:[\"2014-01-01T00:00:00Z\" TO \"#{latest}\"]")
    expect(fetcher.get_date_solr_query(status: 'registered')).to eq('')
  end

  it 'parses druids correctly' do
    expect(fetcher.parse_druid('druid:oo000oo0001')).to eq('oo000oo0001')
    expect(fetcher.parse_druid('oo000oo0001')).to eq('oo000oo0001')
    expect(fetcher.parse_druid('bogousoo000oo0001')).to eq('oo000oo0001')
    expect{ fetcher.parse_druid('bogus') }.to raise_error('invalid druid')
  end

  it 'adds the correct value to the solr params for counting rows' do
    solrparams = { q: { something: 'dude' }, fq: { somethingelse: 'test' } }
    default_max_row = 100_000_000
    expect(fetcher.get_rows(solrparams, rows: 0)).to eq(solrparams.merge(rows: 0))
    expect(fetcher.get_rows(solrparams, {})).to eq(solrparams.merge(rows: default_max_row))
    expect(fetcher.get_rows(solrparams, othercrap: '500')).to eq(solrparams.merge(rows: default_max_row))
    expect(fetcher.get_rows(solrparams, rows: '500')).to eq(solrparams.merge(rows: '500'))
  end

  it 'It should test for picking the proper date out of a range' do
    VCR.use_cassette('last_changed_testing') do
      revs_druid = FixtureData.new.top_level_revs_collection_druid
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
    times = { first: ModificationTime::Y_TEN_K, last: ModificationTime::Y_TEN_K }
    last_changed = ['2014-05-05T05:04:13Z', '2014-04-05T05:04:13Z']
    expect{ fetcher.determine_latest_date(times, last_changed) }.to raise_error(RuntimeError)
  end

  it 'raises an error when object type is not in the OBJECT_TYPES hash' do
    obj_type = 'whatever'
    expect{ fetcher.find_all_object_type({}, obj_type) }.to raise_error(ArgumentError)
  end
end
