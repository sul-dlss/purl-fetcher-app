require 'rails_helper'

describe(V1::DocsController, type: :request, integration: true) do
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
        { druid: "druid:dd111ee2222", latest_change: "2014-01-01T00:00:00Z", true_targets: ["SearchWorksPreview"], collections: ["druid:ff111gg2222"] },
        { druid: "druid:bb111cc2222", latest_change: "2015-01-01T00:00:00Z", true_targets: ["SearchWorks", "Revs", "SearchWorksPreview"], collections: ["druid:ff111gg2222"] },
        { druid: "druid:aa111bb2222", latest_change: "2016-06-06T00:00:00Z", true_targets: ["SearchWorksPreview"], collections: ["druid:gg111hh2222"] },
        { druid: "druid:gg111hh2222", latest_change: "2016-06-08T00:00:00Z", true_targets: ["SearchWorksPreview"] },
        { druid: "druid:hh111ii2222", latest_change: "2016-06-09T00:00:00Z", true_targets: ["SearchWorksPreview"] }
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
        { druid: "druid:dd111ee2222", latest_change: "2014-01-01T00:00:00Z", true_targets: ["SearchWorksPreview"], collections: ["druid:ff111gg2222"] }
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
        { druid: "druid:ff111gg2222", latest_change: "2014-01-01T00:00:00Z" },
        { druid: "druid:cc111dd2222", latest_change: "2016-01-02T00:00:00Z" },
        { druid: "druid:ee111ff2222", latest_change: "2016-01-03T00:00:00Z" }
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
        { druid: "druid:cc111dd2222", latest_change: "2016-01-02T00:00:00Z" },
        { druid: "druid:ee111ff2222", latest_change: "2016-01-03T00:00:00Z" }
      ], pages: pagination_response
    }
    expect(results).to eq(expected_results.with_indifferent_access)
  end
end
