require 'rails_helper'

describe 'Collections routes' do
  it 'has correct routes' do
    expect(get: '/collections').to route_to(
      controller: 'collections', action: 'index', format: 'json'
    )
    expect(get: '/collections/druid:oo000oo0001').to route_to(
      controller: 'collections', action: 'show', format: 'json', id: 'druid:oo000oo0001'
    )
  end
  it 'does not have other routes' do
    expect(get: '/collections/druid:oo000oo0001/edit').not_to be_routable
    expect(post: '/collections/druid:oo000oo0001/edit').not_to be_routable
    expect(delete: '/collections/druid:oo000oo0001').not_to be_routable
    expect(patch: '/collections/druid:oo000oo0001').not_to be_routable
    expect(put: '/collections/druid:oo000oo0001').not_to be_routable
  end
end
