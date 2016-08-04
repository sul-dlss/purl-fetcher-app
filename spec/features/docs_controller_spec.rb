require 'rails_helper'

describe(AboutController, type: :request, integration: true) do
  it "tests the docs changes API call for all time" do
    visit changes_docs_path
    expect(page.status_code).to eq(200)
    #TODO: test expectations, create fixtures?
  end
  it "test the docs changes API call for a specified time period" do
    visit changes_docs_path
    expect(page.status_code).to eq(200)
    #TODO: test expectations, create fixtures?
  end
  it "test the docs deletes API call for all time" do
    visit deletes_docs_path
    expect(page.status_code).to eq(200)
    #TODO: test expectations, create fixtures?
  end
  it "test the docs deletes API call for a specified time period" do
    visit deletes_docs_path
    expect(page.status_code).to eq(200)
    #TODO: test expectations, create fixtures?
  end
end
