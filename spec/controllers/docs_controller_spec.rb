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
    describe 'datetime parameters' do
      it 'fails on bad data' do
        expect { get :changes, :first_modified => 'NOT_A_DATETIME' }.to raise_error(ArgumentError)
        expect { get :changes, :last_modified => 'NOT_A_DATETIME' }.to raise_error(ArgumentError)
      end
      it 'uses default first_modified' do
        get :changes, first_modified: ' ', format: :json
        expect(assigns(:changes).first.druid).to eq 'druid:dd1111ee2222' # oldest
      end
      it 'uses default last_modified' do
        get :changes, last_modified: ' ', format: :json
        expect(assigns(:changes).last.druid).to eq 'druid:bb1111cc2222' # newest
      end
      it 'supports ISO8601 in UTC' do
        get :changes, first_modified: '2014-01-01T00:00:00Z', format: :json
        expect(assigns(:changes).first.druid).to eq 'druid:dd1111ee2222'
      end
      it 'supports ISO8601 in another timezone' do
        get :changes, first_modified: '2014-01-01T00:00:00-01:00', format: :json
        expect(assigns(:changes).first.druid).to eq 'druid:bb1111cc2222' # is in 2013 UTC
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
    describe 'datetime parameters' do
      it 'fails on bad data' do
        expect { get :deletes, :first_modified => 'NOT_A_DATETIME' }.to raise_error(ArgumentError)
        expect { get :deletes, :last_modified => 'NOT_A_DATETIME' }.to raise_error(ArgumentError)
      end
      it 'uses default first_modified' do
        get :deletes, first_modified: ' ', format: :json
        expect(assigns(:deletes).first.druid).to eq 'druid:ee1111ff2222' # oldest
      end
      it 'uses default last_modified' do
        get :deletes, last_modified: ' ', format: :json
        expect(assigns(:deletes).last.druid).to eq 'druid:cc1111dd2222' # newest
      end
      it 'supports ISO8601 in UTC' do
        get :deletes, first_modified: '2014-01-01T00:00:00Z', format: :json
        expect(assigns(:deletes).first.druid).to eq 'druid:ee1111ff2222'
      end
      it 'supports ISO8601 in another timezone' do
        get :deletes, first_modified: '2014-01-01T00:00:00-01:00', format: :json
        expect(assigns(:deletes).first.druid).to eq 'druid:cc1111dd2222' # is in 2013 UTC
      end
    end
  end
end
