require 'rails_helper'

describe 'purls/index.json.jbuilder' do
  before do
    assign(:purls, Kaminari.paginate_array(Purl.all).page(1))
  end
  it 'has pagination' do
    render
    expect(rendered).to match(/pages/)
  end
  it 'always returns "SearchWorksPreview"' do
    render
    expect(rendered).to match(/SearchWorksPreview/)
  end
end
