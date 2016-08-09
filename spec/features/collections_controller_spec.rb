require 'rails_helper'

describe(CollectionsController, type: :request, integration: true) do
  it "fetches all collections" do
    get '/collections'
    expect(response).to be_success
    results = JSON.parse(response.body)
    expect(results).to be_an(Array)
    expect(results).to eq ['druid:ff1111gg2222']
  end

  it "counts the number of collections" do
    get '/collections?rows=0'
    expect(response).to be_success
    results = JSON.parse(response.body)
    expect(results).to be_an(Hash)
    expect(results).to eq({ 'size' => 1 })
  end

  it 'fetches all items that are members of a collection' do
    get '/collections/druid:oo000oo0001'
    expect(response).to be_success
    results = JSON.parse(response.body)
    expect(results).to be_an(Array)
    expect(results).to eq ['druid:bb1111cc2222', 'druid:dd1111ee2222']
  end

  it "counts the items that are members of a collection" do
    get '/collections/druid:oo000oo0001?rows=0'
    expect(response).to be_success
    results = JSON.parse(response.body)
    expect(results).to be_an(Hash)
    expect(results).to eq({ 'size' => 2 })
  end

end
