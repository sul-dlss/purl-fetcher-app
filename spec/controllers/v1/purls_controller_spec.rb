require 'rails_helper'

RSpec.describe V1::PurlsController do
  describe 'GET index' do
    it 'looks up Purl objects using filter' do
      get :index, format: :json
      expect(assigns(:purls)).to be_an ActiveRecord::Relation
      expect(response).to render_template('purls/index')
    end
    describe 'is filterable' do
      it 'by object_type' do
        get :index, format: :json, object_type: 'collection'
        expect(assigns(:purls).first.druid).to eq 'druid:ff111gg2222'
        expect(assigns(:purls).count).to eq 1
      end
    end
    describe 'uses membership scope' do
      it 'to limit non-member objects' do
        get :index, format: :json, membership: 'none'
        expect(assigns(:purls).count).to eq 4
      end
      it 'to limit only objects that are part of a collection' do
        get :index, format: :json, membership: 'collection'
        expect(assigns(:purls).count).to eq 4
      end
    end
    describe 'pagination parameters' do
      it 'per_page' do
        get :index, format: :json, per_page: 1
        expect(assigns(:purls).first.druid).to eq 'druid:ee111ff2222'
        expect(assigns(:purls).count).to eq 1
      end
      it 'page' do
        get :index, format: :json, per_page: 1, page: 2
        expect(assigns(:purls).first.druid).to eq 'druid:ff111gg2222'
        expect(assigns(:purls).count).to eq 1
      end
    end
  end
  describe 'GET show' do
    it 'looks up a Purl by its druid' do
      get :show, druid: 'druid:dd111ee2222', format: :json
      expect(response.status).to eq 200
      expect(assigns(:purl)).to be_an Purl
      expect(response).to render_template('purls/show')
    end
  end
  describe 'PATCH update' do
    let(:purl_object) { create(:purl) }
    it 'updates the purl with new data' do
      purl_object.update(druid: 'druid:bb050dj7711')
      patch :update, druid: 'druid:bb050dj7711', format: :json
      expect(assigns(:purl).title).to eq "This is Pete's New Test title for this object."
    end
  end
end
