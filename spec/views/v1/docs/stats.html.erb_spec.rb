require 'rails_helper'

describe 'v1/docs/stats.html.erb', type: :view do
  before do
    assign(
      :metrics,
      Statistics.new
    )
  end

  it 'renders' do
    render
  end
end
