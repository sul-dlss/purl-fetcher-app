require 'rails_helper'

describe 'v1/docs/changes.json.jbuilder' do
  before do
    assign(:changes, Purl.all.page(1))
  end

  it 'has pagination' do
    render
    data = JSON.parse(rendered, symbolize_names: true)

    expect(data[:changes]).to include hash_including(druid: 'druid:ff111gg2222')
    expect(data[:pages]).to include current_page: 1,
                                    first_page?: true,
                                    last_page?: true,
                                    next_page: nil
  end
  it 'always returns "SearchWorksPreview"' do
    render
    expect(rendered).to match(/SearchWorksPreview/)
  end
end
