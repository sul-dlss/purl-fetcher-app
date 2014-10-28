require 'rails_helper'

describe("Fetcher lib")  do
  
  before :each do
    @fetcher=FetcherTester.new
    @fixture_data = FixtureData.new
  end

  it "should return the current date and time when time not passed in" do
    last_date=Date.tomorrow.to_time.utc.iso8601
    expect(@fetcher.get_times(nil)).to eq({first:'1970-01-01T00:00:00Z',last:last_date})
    expect(@fetcher.get_times({})).to eq({first:'1970-01-01T00:00:00Z',last:last_date})
    expect(@fetcher.get_times({first_modified:nil,last_modified:'01/01/2014'})).to eq({first:'1970-01-01T00:00:00Z',last:"2014-01-01T08:00:00Z"})
    expect(@fetcher.get_times({first_modified:'01/01/2014',last_modified:nil})).to eq({first:'2014-01-01T08:00:00Z',last:last_date})
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
    expected={first:'2010-01-01T18:00:00Z',last:'2011-01-01T18:00:00Z'}
    inputs=[
      {first_modified:'01/01/2010 10:00:00am',last_modified:'01/01/2011 10:00:00am'},
      {first_modified:'2010-01-01T18:00:00Z',last_modified:'01/01/2011 10:00:00am'},
      {first_modified:'01/01/2010 10:00:00am',last_modified:'2011-01-01T18:00:00Z'}
    ]
    inputs.each do |input|
      expect(@fetcher.get_times(input)).to eq(expected)
    end
    expect(@fetcher.get_times({first_modified:'01/01/2010',last_modified:'2011-01-01T18:00:00Z'})).to eq({first:'2010-01-01T08:00:00Z',last:'2011-01-01T18:00:00Z'})
    expect(@fetcher.get_times({first_modified:'2011-01-01T18:00:00Z',last_modified:'2014-12-01'})).to eq({first:'2011-01-01T18:00:00Z',last:'2014-12-01T08:00:00Z'})
    expect(@fetcher.get_times({first_modified:'January 1, 2009',last_modified:'2012-01-01T18:00:00Z'})).to eq({first:'2009-01-01T08:00:00Z',last:'2012-01-01T18:00:00Z'})
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
  
  it "number of Collections found should be all collections when not supplied a date range and all their druids should be present" do
#     target_url = @fixture_data.add_params_to_url(@fixture_data.base_collections_url, {})
     target_url = @fixture_data.add_params_to_url(collections_path, {})
     visit target_url
     response = JSON.parse(page.body)
     
     #We Should Only Have The Four Collection Objects
     expect(response['collection'].size).to eq(@fixture_data.number_of_collections)
      
     #Ensure All Four Collection Druids Are Present
     result_should_contain_druids(@fixture_data.collection_druids_list,response['collection'])
    
     #Ensure No Items Were Returned
     expect(response['items']).to be nil
    
     #Ensure No APOS Were Returned
     expect(response['adminpolicy']).to be nil
     
  end
  
 
  it "number of APOs found should be all APOs when not supplied a date range and all their druids should be present" do
    target_url = @fixture_data.add_params_to_url(apos_path, {})
    visit target_url
    response = JSON.parse(page.body)
    
    #We Should Only Have The Four Collection Objects
    expect(response['adminpolicy'].size).to eq(@fixture_data.number_of_apos)
     
    #Ensure All Four Collection Druids Are Present
    result_should_contain_druids(@fixture_data.apo_druids_list,response['adminpolicy'])
   
    #Ensure No Items Were Returned
    expect(response['items']).to be nil
   
    #Ensure No Collections Were Returned
    expect(response['collection']).to be nil
  end
 
  
  it "It should only return Revs collection objects between these two dates" do
    #All Revs Collection Objects Should Be Here
    #The Stafford Collection Object Should Not Be Here
    
    #Set the dates
    solrparams = {:first_modified =>'2014-01-01T00:00:00Z', :last_modified => '2014-05-06T00:00:00Z'}
    target_url = @fixture_data.add_params_to_url(collections_path, solrparams)
    visit target_url
    response = JSON.parse(page.body)
    
    #We Should Only Have The Three Revs Fixtures
    expect(page).to have_content('"counts":[{"collection":3},{"total_count":3}]}')
    
    #Ensure The Three Revs Collection Driuds Are Present
    result_should_contain_druids(['druid:wy149zp6932','druid:nt028fd5773', 'druid:yt502zj0924'],response['collection'])
    
    #Ensure The Stafford Collection Druid Is Not Present
    result_should_not_contain_druids(['druid:yg867hg1375'], response['collection'])
    
    #Ensure No Items Were Returned
    expect(response['items']).to be nil
    
    #Ensure No APOS Were Returned
    expect(response['adminpolicy']).to be nil
    
  end
  
  def result_should_contain_druids(druids, response)
    response.each do |r|
      expect(druids.include?(r['druid'])).to be true
    end
  
  end
  
  def result_should_not_contain_druids(druids, response)
    response.each do |r|
      expect(druids.include?(r['druid'])).to be false
    end
  
  end
  
  
end
