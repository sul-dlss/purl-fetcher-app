require 'rails_helper'

describe(AboutController, type: :request, integration: true) do
  it 'returns an OK status when calling the root url' do
    visit root_path
    expect(page.status_code).to eq(200)
    expect(page).to have_content('ok')
  end

  it 'returns some info when calling the about/version url' do
    visit about_version_path
    expect(page.status_code).to eq(200)
    expect(page).to have_content(PurlFetcher::Application.config.app_name)
    expect(page).to have_content('test') # Rails.env
  end

  it 'returns some info when calling the about url' do
    visit about_page_engine_path
    expect(page.status_code).to eq(200)
    expect(page).to have_content(PurlFetcher::Application.config.app_name)
    expect(page).to have_content('Dependencies')
  end
end
