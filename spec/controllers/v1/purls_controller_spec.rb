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
        get :index, params: { object_type: 'collection' }, format: :json
        expect(assigns(:purls).first.druid).to eq 'druid:ff111gg2222'
        expect(assigns(:purls).count).to eq 1
      end
    end
    describe 'uses membership scope' do
      it 'to limit non-member objects' do
        get :index, params: { membership: 'none' }, format: :json
        expect(assigns(:purls).count).to eq 4
      end
      it 'to limit only objects that are part of a collection' do
        get :index, params: { membership: 'collection' }, format: :json
        expect(assigns(:purls).count).to eq 4
      end
    end
    describe 'uses status scope' do
      it 'to limit deleted objects' do
        get :index, params: { status: 'deleted' }, format: :json
        expect(assigns(:purls).count).to eq 3
      end
      it 'to limit only objects that are public' do
        get :index, params: { status: 'public' }, format: :json
        expect(assigns(:purls).count).to eq 5
      end
    end
    describe 'uses target scope' do
      it 'to limit targets objects' do
        get :index, params: { target: 'SearchWorks' }, format: :json
        expect(assigns(:purls).count).to eq 2
      end
    end
    describe 'pagination parameters' do
      it 'per_page' do
        get :index, params: { per_page: 1 }, format: :json
        expect(assigns(:purls).first.druid).to eq 'druid:ee111ff2222'
        expect(assigns(:purls).count).to eq 1
      end
      it 'page' do
        get :index, params: { per_page: 1, page: 2 }, format: :json
        expect(assigns(:purls).first.druid).to eq 'druid:ff111gg2222'
        expect(assigns(:purls).count).to eq 1
      end
    end
  end
  describe 'GET show' do
    it 'looks up a Purl by its druid' do
      get :show, params: { druid: 'druid:dd111ee2222' }, format: :json
      expect(response.status).to eq 200
      expect(assigns(:purl)).to be_an Purl
      expect(response).to render_template('purls/show')
    end
    it 'raise a record not found error (returning a 404) when the purl druid is not found' do
      expect { get :show, params: { druid: 'druid:bogus' }, format: :json }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
  describe 'PATCH update' do
    let(:purl_object) { create(:purl) }
    it 'creates a new purl entry' do
      expect do
        patch :update, params: { druid: 'druid:ab012cd3456' }, format: :json
      end.to change(Purl, :count).by(1)
    end
    it 'updates the purl with new data' do
      purl_object.update(druid: 'druid:bb050dj7711')
      patch :update, params: { druid: 'druid:bb050dj7711' }, format: :json
      expect(assigns(:purl).title).to eq "This is Pete's New Test title for this object."
    end
    it 'normalizes the druid parameter' do
      expect do
        patch :update, params: { druid: 'ab012cd3456' }, format: :json
      end.to change(Purl, :count).by(1)
      expect(Purl.first.druid).to eq 'druid:ab012cd3456'
    end
  end
  describe 'DELETE delete' do
    let(:purl_object) { create(:purl) }
    it 'marks the purl as deleted' do
      purl_object.update(druid: 'druid:bb050dj7711')
      delete :destroy, params: { druid: 'druid:bb050dj7711' }, format: :json
      expect(purl_object.reload).to have_attributes(deleted_at: (a_value > Time.current - 5.seconds))
    end
  end
end
