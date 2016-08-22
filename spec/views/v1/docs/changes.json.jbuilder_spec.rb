require 'rails_helper'

describe 'v1/docs/changes.json.jbuilder' do
  before do
    assign(:changes, Kaminari.paginate_array(Purl.all).page(1))
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
