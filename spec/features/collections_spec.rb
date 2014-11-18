require 'rails_helper'

describe("Collections Controller")  do
  before :each do
    @fetcher=FetcherTester.new
    @fixture_data = FixtureData.new
  end
  
  it "the index of Collections found should be all collections when not supplied a date range and all their druids should be present" do
    VCR.use_cassette('all_collections_index_call') do
       visit collections_path
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
      solrparams = {:last_modified =>  last_mod_test_date_collections}
      target_url = collections_path(solrparams)
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
        solrparams = {:first_modified => first_mod_test_date_collections}
        target_url = collections_path(solrparams)
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
      visit collection_path(@fixture_data.top_level_revs_collection_druid)
      with_prefix_response = JSON.parse(page.body)
      
      visit collection_path(@fixture_data.top_level_revs_collection_druid.split(':')[1])
      no_prefix_response = JSON.parse(page.body)
      
      expect(with_prefix_response).to eq(no_prefix_response)
      
      #Check For XML
      visit collection_path(@fixture_data.top_level_revs_collection_druid,:format=>'xml')
      with_prefix_response = page.body
      
      visit collection_path(@fixture_data.top_level_revs_collection_druid.split(':')[1],:format=>'xml')
      no_prefix_response = page.body
      
      expect(with_prefix_response).to eq(no_prefix_response)
    end
  end
  
  it "should return only the Revs Druids when a collection is queried with the top level Revs Collection" do
    VCR.use_cassette('revs_collection_call') do
      visit collection_path(@fixture_data.top_level_revs_collection_druid)
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
      visit collection_path(@fixture_data.top_level_revs_collection_druid, just_count_param)
      
      expect(page.body.to_i).to eq((@fixture_data.revs_items_druids+@fixture_data.revs_collections_druids).size)
    end
    
  end
  
  it "should respect first modified when asked for just a count" do
    VCR.use_cassette('collection_count_call_first_modified') do
      visit collections_path(just_count_param.merge(:first_modified => first_mod_test_date_collections))
      expect(page.body.to_i).to eq(@fixture_data.revs_collections_druids.size)
    end
  end
  
  it "should respect last modified when asked for just a count" do
    VCR.use_cassette('collection_count_call_last_modified') do
      visit collections_path(just_count_param.merge(:last_modified => last_mod_test_date_collections))
      expect(page.body.to_i).to eq(@fixture_data.stafford_collections_druids.size)
    end
  end
  
  it "should return just the subcollection for revs when called with a revs subcollection druid" do
    VCR.use_cassette('revs_subcollection_call_last_modified') do
      visit collection_path(@fixture_data.revs_subcollection_druid)
      response = JSON.parse(page.body)
      collections_list = [@fixture_data.revs_subcollection_druid]
     
      
      #Ensure Subcollection Druid is Present
      result_should_contain_druids(collections_list,response[collections_key]) 
      
      #Ensure No Other Collection Druids Are Present
      result_should_not_contain_druids(@fixture_data.all_collection_druids-collections_list,response[collections_key]) 
      
      #Verify the Counts
      verify_counts_section(response, {collections_key => collections_list.size, items_key => 4})
      
    end
  end
  
  it "should return a blank title if both expected title fields are not present in a solr doc" do
    VCR.use_cassette('nt028fd5773 collection', :allow_unused_http_interactions => true) do
      visit collection_path(:id=>"nt028fd5773")
      response = JSON.parse(page.body)
      expect(response['items'].size).to eq(8) # there should be 8 items in this collection
      response['items'].each do |item|
        if item['druid'] == 'druid:bb048rn5648' # this item is missing the title field in both places, and so the title should be blank
          expect(item['title']).to eq("")
        elsif item['druid'] == 'druid:bb113tm9924' # this item has the title field in the alternate spot, and should still come through ok
          expect(item['title']).to eq("Permatex 300 NASCAR Race: 1968")
        else
          expect(item['title']).not_to eq("") # the rest should have a title
        end
      end
    end
  end
  
  it "It should only return Revs collection objects between these two dates" do
     VCR.use_cassette('revs_objects_dates', :allow_unused_http_interactions => true) do
      #All Revs Collection Objects Should Be Here
      #The Stafford Collection Object Should Not Be Here
    
      #Set the dates
      solrparams = {:first_modified =>'2014-01-01T00:00:00Z', :last_modified => '2014-05-06T00:00:00Z'}
      target_url = collections_path(solrparams)
      visit target_url
      response = JSON.parse(page.body)
    
      #We Should Only Have The Three Revs Fixtures
      expect(response[counts_key][collections_key]).to eq(3)
      
      #Ensure The Three Revs Collection Driuds Are Present
      result_should_contain_druids(@fixture_data.revs_collections_druids,response[collections_key])
    
      #Ensure The Stafford Collection Druid Is Not Present
      result_should_not_contain_druids(@fixture_data.all_collection_druids-@fixture_data.revs_collections_druids, response[collections_key])
    
      #Ensure No Items Were Returned
      expect(response[items_key]).to be nil
    
      #Ensure No APOS Were Returned
      expect(response[apos_key]).to be nil
    end
  end
  
  
end