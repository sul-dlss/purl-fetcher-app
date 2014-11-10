require 'rails_helper'

describe("Ping",:type=>:request,:integration=>true)  do
  
  it "should return an OK status when calling the root url" do
    visit root_path
    expect(page.status_code).to eq(200)
    expect(page).to have_content('ok')
  end

end
  