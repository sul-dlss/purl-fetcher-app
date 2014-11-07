require 'rails_helper'

describe("Fetcher lib")  do
  
  before :each do
    @fetcher=FetcherTester.new
    @fixture_data = FixtureData.new
    @earliest='1970-01-01T00:00:00Z'
  end

  it "should return the current date and time when time not passed in" do
    last_date=Time.zone.now.end_of_day.iso8601
    expect(@fetcher.get_times(nil)).to eq({first:@earliest,last:last_date})
    expect(@fetcher.get_times({})).to eq({first:@earliest,last:last_date})
    expect(@fetcher.get_times({first_modified:nil,last_modified:'01/01/2014'})).to eq({first:'1970-01-01T00:00:00Z',last:"2014-01-01T00:00:00Z"})
    expect(@fetcher.get_times({first_modified:'01/01/2014',last_modified:nil})).to eq({first:'2014-01-01T00:00:00Z',last:last_date})
  end  
  
  it "should raise an exception if the start date is not before the end date" do
    expect{@fetcher.get_times({first_modified:'01/01/2010 10:00:00am',last_modified:'01/01/2009 10:00:00am'})}.to raise_error("start time is before end time") 
    expect{@fetcher.get_times({first_modified:'01/01/2010 10:00:00am',last_modified:'01/01/2010 10:00:00am'})}.to raise_error("start time is before end time") 
    expect{@fetcher.get_times({first_modified:'01/01/2010 10:00:00am',last_modified:'01/01/2010 10:00:01am'})}.not_to raise_error
  end
  
  it "should raise an exception for either starting of ending date in an invalid format" do
    expect{@fetcher.get_times({first_modified:'01/01/2010 10:00:00am',last_modified:'ness'})}.to raise_error("invalid time paramaters")
    expect{@fetcher.get_times({first_modified:'bogus',last_modified:'01/01/2010 10:00:00am'})}.to raise_error("invalid time paramaters")
    expect{@fetcher.get_times({first_modified:'bogus',last_modified:'ness'})}.to raise_error("invalid time paramaters")
  end

  it "should return the properly formatted hash for various valid types of input date or time" do
    expected={first:'2010-01-01T10:00:00Z',last:'2011-01-01T10:00:00Z'}
    inputs=[
      {first_modified:'01/01/2010 10:00:00am',last_modified:'01/01/2011 10:00:00am UTC'},
      {first_modified:'2010-01-01T02:00:00 PST',last_modified:'01/01/2011 2:00:00am PST'},
      {first_modified:'01/01/2010 10:00:00am',last_modified:'2011-01-01T10:00:00Z'}
    ]
    inputs.each do |input|
      expect(@fetcher.get_times(input)).to eq(expected)
    end
    expect(@fetcher.get_times({first_modified:'01/01/2010',last_modified:'2011-01-01T18:00:00Z'})).to eq({first:'2010-01-01T00:00:00Z',last:'2011-01-01T18:00:00Z'})
    expect(@fetcher.get_times({first_modified:'2011-01-01T18:00:00Z',last_modified:'2014-12-01'})).to eq({first:'2011-01-01T18:00:00Z',last:'2014-12-01T00:00:00Z'})
    expect(@fetcher.get_times({first_modified:'January 1, 2009',last_modified:'2012-01-01T18:00:00Z'})).to eq({first:'2009-01-01T00:00:00Z',last:'2012-01-01T18:00:00Z'})
  end

  it "should parse druids correctly" do
    expect(@fetcher.parse_druid('druid:oo000oo0001')).to eq('oo000oo0001')
    expect(@fetcher.parse_druid('oo000oo0001')).to eq('oo000oo0001')
    expect(@fetcher.parse_druid('bogousoo000oo0001')).to eq('oo000oo0001')
    expect{@fetcher.parse_druid('bogus')}.to raise_error('invalid druid')
  end
  
  it "should add the correct value to the solr params for counting rows" do
    solrparams={:q=>{:something=>'dude'},:fq=>{:somethingelse=>'test'}}
    default_max_row=100000000
    expect(@fetcher.get_rows(solrparams,{:rows=>0})).to eq(solrparams.merge(:rows=>0))
    expect(@fetcher.get_rows(solrparams,{})).to eq(solrparams.merge(:rows=>default_max_row))
    expect(@fetcher.get_rows(solrparams,{:othercrap=>'500'})).to eq(solrparams.merge(:rows=>default_max_row))   
    expect(@fetcher.get_rows(solrparams,{:rows=>'500'})).to eq(solrparams.merge(:rows=>'500'))    
  end
  

    
  it "It should test for picking the proper date out of a range" do
    VCR.use_cassette('last_changed_testing') do
       latest_change = 'latest_change'
       solrparams = just_late_end_date  #We need the time to be a stable time way in the future for VCR recordings
       target_url = add_params_to_url(collections_path + '/' + @fixture_data.top_level_revs_collection_druid, solrparams)
       visit target_url
       response = JSON.parse(page.body)
       collections = response[collections_key]
       d = find_druid_in_array(collections, @fixture_data.top_level_revs_collection_druid)
       expect(d[latest_change]).to eq('2014-06-06T05:06:06Z')
      
       new_url= add_params_to_url(collections_path + '/' + @fixture_data.top_level_revs_collection_druid, {:last_modified =>  '2014-06-05T05:06:06Z'})
       visit new_url
       response = JSON.parse(page.body)
       collections = response[collections_key]
       d = find_druid_in_array(collections, @fixture_data.top_level_revs_collection_druid)
       expect(d[latest_change]).to eq('2014-05-05T05:04:13Z')
     end 
  end
  
  
  
  
end