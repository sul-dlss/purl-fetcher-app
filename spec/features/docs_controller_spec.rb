require 'rails_helper'

describe(AboutController, type: :request, integration: true) do
  let(:pagination_response) do
    {
      current_page: 1,
      next_page: nil,
      prev_page: nil,
      total_pages: 1,
      per_page: 100,
      offset_value: 0,
      first_page?: true,
      last_page?: true
    }
  end
  it "tests the docs changes API call for all time" do
    get changes_docs_path
    expect(response).to be_success
    results = JSON.parse(response.body)
    expected_results = { changes:
      [
        { druid: "druid:dd1111ee2222", latest_change: "2014-01-01T00:00:00Z",  collections: ["druid:oo000oo0001"] },
        { druid: "druid:bb1111cc2222", latest_change: "2015-01-01T00:00:00Z", true_targets: ["SearchWorks", "Revs"], collections: ["druid:oo000oo0001", "druid:oo000oo0002"] }
      ],
      pages: pagination_response
    }
    expect(results).to eq(expected_results.with_indifferent_access)
  end
  it "test the docs changes API call for a specified time period" do
    get changes_docs_path(first_modified: Time.zone.parse('2013/12/31').iso8601, last_modified: Time.zone.parse('2014/01/02').iso8601)
    expect(response).to be_success
    results = JSON.parse(response.body)
    expected_results = { changes:
      [
        { druid: "druid:dd1111ee2222", latest_change: "2014-01-01T00:00:00Z", collections: ["druid:oo000oo0001"] }
      ], pages: pagination_response
    }
    expect(results).to eq(expected_results.with_indifferent_access)
  end
  it "test the docs deletes API call for all time" do
    get deletes_docs_path
    expect(response).to be_success
    results = JSON.parse(response.body)
    expected_results = { deletes:
      [
        { druid: "druid:ee1111ff2222", latest_change: "2014-01-01T00:00:00Z" },
        { druid: "druid:ff1111gg2222", latest_change: "2014-01-01T00:00:00Z" },
        { druid: "druid:cc1111dd2222", latest_change: "2016-01-02T00:00:00Z" }
      ], pages: pagination_response
    }
    expect(results).to eq(expected_results.with_indifferent_access)
  end
  it "test the docs deletes API call for a specified time period" do
    get deletes_docs_path(first_modified: Time.zone.parse('2015/12/31').iso8601, last_modified: Time.zone.parse('2016/01/03').iso8601)
    expect(response).to be_success
    results = JSON.parse(response.body)
    expected_results = { deletes:
      [
        { druid: "druid:cc1111dd2222", latest_change: "2016-01-02T00:00:00Z" }
      ], pages: pagination_response
    }
    expect(results).to eq(expected_results.with_indifferent_access)
  end
end
