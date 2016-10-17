require 'rails_helper'

RSpec.describe ApplicationController do
  describe 'GET root' do
    it 'gets the root of the application' do
      get :default
      expect(response.status).to eq 200
    end
  end
end