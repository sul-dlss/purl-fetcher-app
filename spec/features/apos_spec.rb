require 'rails_helper'

describe("APOS Controller")  do
  before :each do
    @fetcher=FetcherTester.new
    @fixture_data = FixtureData.new
  end
  
  it "the index of APOS found should be all APOS when not supplied a date range and all their druids should be present" do
    VCR.use_cassette('all_apos_index_call') do
       visit apos_path
       response = JSON.parse(page.body)
     
       #Ensure All APO Druids Are Present
       result_should_contain_druids(@fixture_data.all_apo_druids,response[apos_key])
       
       #Ensure No Other Druids Are Present
       result_should_not_contain_druids(@fixture_data.accessioned_druids-@fixture_data.all_apo_druids,response[apos_key]) 
    
       #Ensure No Items Were Returned
       expect(response[items_key]).to be nil
    
       #Ensure No Collections Were Returned
       expect(response[collections_key]).to be nil
       
       #Verify the Counts
       verify_counts_section(response, {apos_key => @fixture_data.all_apo_druids.size})
     end
     
  end
  
  it "the index of APOS should respect :last_modified and return only Stafford" do
    VCR.use_cassette('last_modified_date_apos_index_call') do
      solrparams = {:last_modified =>  mod_test_date_apos}
      target_url = apos_path(solrparams)
      visit target_url
      response = JSON.parse(page.body)
      #Ensure the Stafford Apo Druid is Present
      result_should_contain_druids([@fixture_data.stafford_apo_druid],response[apos_key]) 
      
      #Ensure No Other Apos Druids Are Present
      result_should_not_contain_druids(@fixture_data.accessioned_druids-[@fixture_data.stafford_apo_druid],response[apos_key]) 
      
      #Ensure No Items Were Returned
      expect(response[items_key]).to be nil
   
      #Ensure No Collections Were Returned
      expect(response[collections_key]).to be nil
      
      #Verify the Counts
      verify_counts_section(response, {apos_key => 1})
    end
  end
    
    it "the index of APOS should return both Revs and Stafford with first modifed date because Stafford APO has multiple edit dates" do
      VCR.use_cassette('first_modified_date_apos_index_call') do
        target_url = apos_path(:first_modified => mod_test_date_apos)
        visit target_url
        response = JSON.parse(page.body)
        
        #Ensure the all Apo Druids are Present
        result_should_contain_druids(@fixture_data.all_apo_druids,response[apos_key]) 

        #Ensure No Other Druids Are Present
        result_should_not_contain_druids(@fixture_data.accessioned_druids-@fixture_data.all_apo_druids,response[apos_key]) 

        #Ensure No Items Were Returned
        expect(response[items_key]).to be nil

        #Ensure No Collections Were Returned
        expect(response[collections_key]).to be nil

        #Verify the Counts
        verify_counts_section(response, {apos_key => @fixture_data.all_apo_druids.size})
      end
    
  end
  
  it "should not need the druid: prefix to query a list of druids from apos" do
    VCR.use_cassette('prefix_and_no_prefix_calls_to_apo') do
      
      #Check For JSON
      visit apo_path(@fixture_data.all_apo_druids[0])
      with_prefix_response = JSON.parse(page.body)
      
      visit apo_path(@fixture_data.all_apo_druids[0].split(':')[1])
      no_prefix_response = JSON.parse(page.body)
      
      expect(with_prefix_response).to eq(no_prefix_response)
      
      #Check For XML
      visit apo_path(@fixture_data.all_apo_druids[0],:format=>'xml')
      with_prefix_response = page.body
      
      visit apo_path(@fixture_data.all_apo_druids[0].split(':')[1],:format=>'xml')
      no_prefix_response = page.body
      
      expect(with_prefix_response).to eq(no_prefix_response)
    end
  end
  
  it "should return only the Revs Druids when an APO is queried with the Revs APO" do
    VCR.use_cassette('revs_apo_call') do
      visit apo_path(@fixture_data.revs_apo_druid)
      response = JSON.parse(page.body)
      exclude_druids = @fixture_data.revs_items_druids+@fixture_data.revs_collections_druids+[@fixture_data.revs_apo_druid]
      
      #Ensure All Revs Collection Druids Are Present
      result_should_contain_druids(@fixture_data.revs_collections_druids,response[collections_key])
      
      #Ensure Not Other Collections Are Present
      result_should_not_contain_druids(@fixture_data.accessioned_druids-exclude_druids,response[collections_key]) 
      
      #Ensure All Revs Items Are Present
      result_should_contain_druids(@fixture_data.revs_items_druids,response[items_key])
      
      #Ensure No Other Items Are Present
      result_should_not_contain_druids(@fixture_data.accessioned_druids-exclude_druids,response[items_key]) 
      
      #Ensure Revs APO Is Present
      result_should_contain_druids([@fixture_data.revs_apo_druid],response[apos_key]) 
      
      #Ensure No Other APOs Are Present
      result_should_not_contain_druids(@fixture_data.accessioned_druids-exclude_druids,response[apos_key]) 
      
      
      #Verify the Counts
      verify_counts_section(response, {collections_key => @fixture_data.revs_collections_druids.size, items_key => @fixture_data.revs_items_druids.size, apos_key => 1})
    end
  end
  
  it "should only return a count of the Revs Druids when called with the count only parameter" do
    VCR.use_cassette('revs_apo_count_call') do
      visit apo_path(@fixture_data.revs_apo_druid, just_count_param)
      
      #The One is the APO
      expect(page.body.to_i).to eq((@fixture_data.revs_items_druids+@fixture_data.revs_collections_druids).size+1)
    end
    
  end
  
  it "should respect first modified when asked for just a count" do
    VCR.use_cassette('apo_count_call_first_modified') do
      visit apos_path(just_count_param.merge(:first_modified => first_mod_test_date_apos))
      
      #Only Stafford Druid
      expect(page.body.to_i).to eq(1)
    end
  end
  
  it "should respect last modified when asked for just a count" do
    VCR.use_cassette('apos_count_call_last_modified') do
      visit apos_path(just_count_param.merge(:last_modified =>mod_test_date_apos))
      expect(page.body.to_i).to eq(1)
    end
  end
  
end