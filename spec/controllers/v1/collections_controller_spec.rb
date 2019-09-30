require 'rails_helper'

RSpec.describe V1::CollectionsController do
  describe 'GET index' do
    it 'looks up Purl objects where object_type is collection' do
      get :index, format: :json
      expect(assigns(:collections)).to be_an ActiveRecord::Relation
      expect(assigns(:collections).first.druid).to eq 'druid:ff111gg2222'
      expect(response).to render_template('collections/index')
    end

    describe 'pagination parameters' do
      it 'per_page' do
        get :index, params: { per_page: 1 }, format: :json
        expect(assigns(:collections).first.druid).to eq 'druid:ff111gg2222'
        expect(assigns(:collections).count).to eq 1
      end

      it 'page' do
        get :index, params: { per_page: 1, page: 2 }, format: :json
        expect(assigns(:collections).first.druid).to eq 'druid:gg111hh2222'
        expect(assigns(:collections).count).to eq 1
      end
    end
  end

  describe 'GET show' do
    it 'looks up a Purl by its druid' do
      get :show, params: { druid: 'druid:ff111gg2222' }, format: :json
      expect(response.status).to eq 200
      expect(assigns(:collection)).to be_an Purl
      expect(response).to render_template('collections/show')
    end

    it 'raise a record not found error (returning a 404) when the collection druid is not found' do
      expect { get :show, params: { druid: 'druid:bogus' }, format: :json }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'GET purls' do
    it 'purls for a selected collection' do
      get :purls, params: { druid: 'druid:ff111gg2222' }, format: :json
      expect(assigns(:purls).first.druid).to eq 'druid:dd111ee2222'
      expect(assigns(:purls).count).to eq 3
    end
  end
end
