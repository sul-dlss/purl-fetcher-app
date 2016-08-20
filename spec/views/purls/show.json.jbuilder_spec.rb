require 'rails_helper'

describe 'purls/show.json.jbuilder' do
  before do
    assign(:purl, Purl.first)
  end
  it 'renders purl partial' do
    render
    expect(JSON.parse(rendered)).to include('collections' => ['druid:oo000oo0002'], 'druid' => 'druid:ee111ff2222')
  end
  it 'always returns "SearchWorksPreview"' do
    render
    expect(rendered).to match(/SearchWorksPreview/)
  end
end
