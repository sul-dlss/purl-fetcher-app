require 'rails_helper'

RSpec.describe DocsController do
  describe '#changes' do
    it 'assigns and renders template' do
      get :changes, format: :json
      expect(assigns(:changes)).to be_an ActiveRecord::Relation
      expect(response).to render_template('changes')
    end
    describe 'pagination parameters' do
      it 'per_page' do
        get :changes, format: :json, per_page: 1
        expect(assigns(:changes).first.druid).to eq 'druid:dd1111ee2222'
        expect(assigns(:changes).count).to eq 1
      end
      it 'page' do
        get :changes, format: :json, per_page: 1, page: 2
        expect(assigns(:changes).first.druid).to eq 'druid:bb1111cc2222'
        expect(assigns(:changes).count).to eq 1
      end
    end
  end
  describe '#deletes' do
    it 'assigns and renders template' do
      get :deletes, format: :json
      expect(assigns(:deletes)).to be_an ActiveRecord::Relation
      expect(response).to render_template('deletes')
    end
    describe 'pagination parameters' do
      it 'per_page' do
        get :deletes, format: :json, per_page: 1
        expect(assigns(:deletes).first.druid).to eq 'druid:ee1111ff2222'
        expect(assigns(:deletes).count).to eq 1
      end
      it 'page' do
        get :deletes, format: :json, per_page: 1, page: 2
        expect(assigns(:deletes).first.druid).to eq 'druid:ff1111gg2222'
        expect(assigns(:deletes).count).to eq 1
      end
    end
  end
end
