require 'rails_helper'

describe("Collections Controller")  do
  before :each do
    @fetcher=FetcherTester.new
    @fixture_data = FixtureData.new
    #@earliest='1970-01-01T00:00:00Z'
  end
  
  it "the index of Collections found should be all collections when not supplied a date range and all their druids should be present" do
#     target_url = @fixture_data.add_params_to_url(@fixture_data.base_collections_url, {})
    VCR.use_cassette('all_collections_index_call',  :allow_unused_http_interactions => true) do
       solrparams = just_late_end_date  #We need the time to be a stable time way in the future for VCR recordings
       target_url = add_params_to_url(collections_path, solrparams)
       visit target_url
       response = JSON.parse(page.body)
     
       #We Should Only Have The Four Collection Objects
       expect(response[collections_key].size).to eq(@fixture_data.number_of_collections)
      
       #Ensure All Four Collection Druids Are Present
       result_should_contain_druids(@fixture_data.collection_druids_list,response['collections'])
    
       #Ensure No Items Were Returned
       expect(response[items_key]).to be nil
    
       #Ensure No APOS Were Returned
       expect(response[apos_key]).to be nil
     end
     
  end
  
  it "the index of Collections should respect :last_modified and return only Stafford" do
    VCR.use_cassette('last_modified_date_collections_index_call') do
      solrparams = {:last_modified => '2013-12-31T23:59:59Z'}
      target_url = add_params_to_url(collections_path, solrparams)
      visit target_url
      response = JSON.parse(page.body)
      
      #We Should Only Have The One Collection Object
      expect(response[collections_key].size).to eq(1)
      
      #Ensure the Stafford Collection Druid is Present
      result_should_contain_druids(@fixture_data.stafford_collections_druids,response[collections_key]) 
      
      #Ensure the Revs Collection Druids Are Not Present
      result_should_not_contain_druids(@fixture_data.revs_collections_druids,response[collections_key]) 
      
      #Ensure No Items Were Returned
      expect(response[items_key]).to be nil
   
      #Ensure No APOS Were Returned
      expect(response[apos_key]).to be nil
    end
  end
    
    it "the index of Collections should respect :first_modified and return only Revs" do
      VCR.use_cassette('first_modified_date_collections_index_call') do
        solrparams = {:first_modified => '2014-1-1T00:00:00Z'}
        target_url = add_params_to_url(collections_path, solrparams)
        visit target_url
        response = JSON.parse(page.body)
      
        #We Should Only Have The Three Revs Collection Objects
        expect(response[collections_key].size).to eq(3)
      
        #Ensure All Three Revs Collection Druids Are Present
        result_should_contain_druids(@fixture_data.revs_collections_druids,response[collections_key])
        
        #Ensure The Stafford Collection Druid Is Not Present
        result_should_not_contain_druids(@fixture_data.stafford_collections_druids,response[collections_key]) 
      
        #Ensure No Items Were Returned
        expect(response[items_key]).to be nil
   
        #Ensure No APOS Were Returned
        expect(response[apos_key]).to be nil
      end
    
  end
end