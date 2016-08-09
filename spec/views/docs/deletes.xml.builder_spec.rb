require 'rails_helper'

describe 'docs/deletes.xml.builder' do
  before do
    assign(
      :deletes,
      Kaminari.paginate_array(
        Purl.where(deleted_at: Time.zone.at(0).iso8601..Time.zone.now.iso8601)
      ).page(1)
    )
  end
  it 'has pagination' do
    render
    expect(rendered).to match(/<pages>/)
  end
end
