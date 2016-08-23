require 'rails_helper'

describe 'v1/purls/_purl.json.jbuilder' do
  it 'renders appropriate fields' do
    render partial: 'v1/purls/purl', locals: { purl: Purl.first }
    expect(JSON.parse(rendered)).to include(
      'collections' => ['druid:oo000oo0002'],
      'druid' => 'druid:ee111ff2222',
      'object_type' => 'set',
      'true_targets' => ['SearchWorksPreview'],
      'catkey' => '',
      'title' => 'Some test object number 4'
    )
  end
  it 'always returns "SearchWorksPreview"' do
    render partial: 'v1/purls/purl', locals: { purl: Purl.first }
    expect(rendered).to match(/SearchWorksPreview/)
  end
end