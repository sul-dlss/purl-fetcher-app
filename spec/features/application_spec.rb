require 'rails_helper'

describe("Application")  do
    it "should display okay on the index page to show it is working." do
      VCR.use_cassette('main_page') do
        visit root_path
        expect(page.body).to eq('ok')
      end
    end
end