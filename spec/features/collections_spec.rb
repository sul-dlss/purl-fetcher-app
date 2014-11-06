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
     
       #Ensure All Four Collection Druids Are Present
       result_should_contain_druids(@fixture_data.all_collection_druids,response[collections_key])
       
       #Ensure No Other Druids Are Present
       result_should_not_contain_druids(@fixture_data.all_druids-@fixture_data.all_collection_druids,response[collections_key]) 
    
       #Ensure No Items Were Returned
       expect(response[items_key]).to be nil
    
       #Ensure No APOS Were Returned
       expect(response[apos_key]).to be nil
       
       #Verify the Counts
       verify_counts_section(response, {collections_key => @fixture_data.all_collection_druids.size})
     end
     
  end
  
  it "the index of Collections should respect :last_modified and return only Stafford" do
    VCR.use_cassette('last_modified_date_collections_index_call') do
      solrparams = {:last_modified =>  last_mod_test_date}
      target_url = add_params_to_url(collections_path, solrparams)
      visit target_url
      response = JSON.parse(page.body)
      
      #Ensure the Stafford Collection Druid is Present
      result_should_contain_druids(@fixture_data.stafford_collections_druids,response[collections_key]) 
      
      #Ensure No Other Collection Druids Are Present
      result_should_not_contain_druids(@fixture_data.all_druids-@fixture_data.stafford_collections_druids,response[collections_key]) 
      
      #Ensure No Items Were Returned
      expect(response[items_key]).to be nil
   
      #Ensure No APOS Were Returned
      expect(response[apos_key]).to be nil
      
      #Verify the Counts
      verify_counts_section(response, {collections_key => @fixture_data.stafford_collections_druids.size})
    end
  end
    
    it "the index of Collections should respect :first_modified and return only Revs" do
      VCR.use_cassette('first_modified_date_collections_index_call') do
        solrparams = {:first_modified => first_mod_test_date}
        target_url = add_params_to_url(collections_path, solrparams)
        visit target_url
        response = JSON.parse(page.body)
      
        #Ensure All Three Revs Collection Druids Are Present
        result_should_contain_druids(@fixture_data.revs_collections_druids,response[collections_key])
        
        #Ensure Not Other Collections Are Present
        result_should_not_contain_druids(@fixture_data.all_druids-@fixture_data.revs_collections_druids,response[collections_key]) 
      
        #Ensure No Items Were Returned
        expect(response[items_key]).to be nil
   
        #Ensure No APOS Were Returned
        expect(response[apos_key]).to be nil
        
        #Verify the Counts
        verify_counts_section(response, {collections_key => @fixture_data.revs_collections_druids.size})
      end
    
  end
  
  it "should not need the druid: prefix to query a list of druids from collections" do
    VCR.use_cassette('prefix_and_no_prefix_calls_to_collection') do
      
      #Check For JSON
      visit collections_path + '/' + @fixture_data.top_level_revs_collection_druid
      with_prefix_response = JSON.parse(page.body)
      
      visit collections_path + '/' + @fixture_data.top_level_revs_collection_druid.split(':')[1]
      no_prefix_response = JSON.parse(page.body)
      
      expect(with_prefix_response).to eq(no_prefix_response)
      
      #Check For XML
      visit collections_path + '/' + @fixture_data.top_level_revs_collection_druid + '.xml'
      with_prefix_response = page.body
      
      visit collections_path + '/' + @fixture_data.top_level_revs_collection_druid.split(':')[1] + '.xml'
      no_prefix_response = page.body
      
      expect(with_prefix_response).to eq(no_prefix_response)
    end
  end
  
  it "should return only the Revs Druids when a collection is queried with the top level Revs Collection" do
    VCR.use_cassette('revs_collection_call') do
      visit collections_path + '/' + @fixture_data.top_level_revs_collection_druid
      response = JSON.parse(page.body)
      exclude_druids = @fixture_data.revs_items_druids+@fixture_data.revs_collections_druids
      
      #Ensure All Revs Collection Druids Are Present
      result_should_contain_druids(@fixture_data.revs_collections_druids,response[collections_key])
      
      #Ensure Not Other Collections Are Present
      result_should_not_contain_druids(@fixture_data.all_druids-exclude_druids,response[collections_key]) 
      
      #Ensure All Revs Items Are Present
      result_should_contain_druids(@fixture_data.revs_items_druids,response[items_key])
      
      #Ensure No Other Items Are Present
      result_should_not_contain_druids(@fixture_data.all_druids-exclude_druids,response[items_key]) 
      
      #Ensure No APOS Are Present
      expect(response[apos_key]).to be nil
      
      #Verify the Counts
      verify_counts_section(response, {collections_key => @fixture_data.revs_collections_druids.size, items_key => @fixture_data.revs_items_druids.size})
    end
  end
  
  it "should only return a count of the Revs Druids when called with the count only parameter" do
    VCR.use_cassette('revs_collection_count_call') do
      visit add_params_to_url(collections_path + '/' + @fixture_data.top_level_revs_collection_druid, just_count_param)
      
      expect(page.body.to_i).to eq((@fixture_data.revs_items_druids+@fixture_data.revs_collections_druids).size)
    end
    
  end
  
  it "should respect first modified when asked for just a count" do
    VCR.use_cassette('collection_count_call_first_modified') do
      visit add_params_to_url(collections_path, just_count_param.merge(:first_modified => first_mod_test_date))
      expect(page.body.to_i).to eq(@fixture_data.revs_collections_druids.size)
    end
  end
  
  it "should respect last modified when asked for just a count" do
    VCR.use_cassette('collection_count_call_last_modified') do
      visit add_params_to_url(collections_path, just_count_param.merge(:last_modified => last_mod_test_date))
      expect(page.body.to_i).to eq(@fixture_data.stafford_collections_druids.size)
    end
  end
  
end