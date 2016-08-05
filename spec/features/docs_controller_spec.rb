require 'rails_helper'

describe(AboutController, type: :request, integration: true) do
  it "tests the docs changes API call for all time" do
    get changes_docs_path
    expect(response).to be_success
    results = JSON.parse(response.body)
    expected_results = { changes:
      [
        { druid: "druid:bb1111cc2222", latest_change: "2015-01-01T08:00:00.000Z", true_targets: ["SearchWorks", "Revs"], false_targets: [], collections: ["druid:oo000oo0001", "druid:oo000oo0002"] },
        { druid: "druid:dd1111ee2222", latest_change: "2014-01-01T08:00:00.000Z", true_targets: [], false_targets: [], collections: ["druid:oo000oo0001"] }
      ]
    }
    expect(results).to eq(expected_results.with_indifferent_access)
  end
  it "test the docs changes API call for a specified time period" do
    get changes_docs_path(first_modified: Time.zone.parse('2013/12/31').utc.iso8601, last_modified: Time.zone.parse('2014/01/02').utc.iso8601)
    expect(response).to be_success
    results = JSON.parse(response.body)
    expected_results = { changes:
      [
        { druid: "druid:dd1111ee2222", latest_change: "2014-01-01T08:00:00.000Z", true_targets: [], false_targets: [], collections: ["druid:oo000oo0001"] }
      ]
    }
    expect(results).to eq(expected_results.with_indifferent_access)
  end
  it "test the docs deletes API call for all time" do
    get deletes_docs_path
    expect(response).to be_success
    results = JSON.parse(response.body)
    expected_results = { deletes:
      [
        { druid: "druid:ee1111ff2222", latest_change: "2014-01-01T08:00:00.000Z" },
        { druid: "druid:cc1111dd2222", latest_change: "2016-01-02T08:00:00.000Z" }
      ]
    }
    expect(results).to eq(expected_results.with_indifferent_access)
  end
  it "test the docs deletes API call for a specified time period" do
    get deletes_docs_path(first_modified: Time.zone.parse('2015/12/31').utc.iso8601, last_modified: Time.zone.parse('2016/01/03').utc.iso8601)
    expect(response).to be_success
    results = JSON.parse(response.body)
    expected_results = { deletes:
      [
        { druid: "druid:cc1111dd2222", latest_change: "2016-01-02T08:00:00.000Z" }
      ]
    }
    expect(results).to eq(expected_results.with_indifferent_access)
  end
end
