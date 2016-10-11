require 'rails_helper'

describe 'v1/purls/_purl.json.jbuilder' do
  it 'renders appropriate fields' do
    render partial: 'v1/purls/purl', locals: { purl: Purl.find(1) }
    expect(JSON.parse(rendered)).to include(
      'collections' => ['druid:ff111gg2222'],
      'druid' => 'druid:bb111cc2222',
      'object_type' => 'item',
      'catkey' => '',
      'title' => 'Some test object'
    )
  end
  it 'always returns "SearchWorksPreview" for non deleted Purls' do
    render partial: 'v1/purls/purl', locals: { purl: Purl.where(deleted_at: nil).first }
    expect(rendered).to match(/SearchWorksPreview/)
  end
end
