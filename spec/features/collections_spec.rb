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
       expect(response['collections'].size).to eq(@fixture_data.number_of_collections)
      
       #Ensure All Four Collection Druids Are Present
       result_should_contain_druids(@fixture_data.collection_druids_list,response['collections'])
    
       #Ensure No Items Were Returned
       expect(response['items']).to be nil
    
       #Ensure No APOS Were Returned
       expect(response['adminpolicies']).to be nil
     end
     
  end
  
  xit "the index of Collections should respect the date" do
    VCR.use_cassette('date_collections_index_call') do
      solrparams = just_late_end_date
      target_url = add_params_to_url(collections_path, solrparams)
    end
    
  end
end