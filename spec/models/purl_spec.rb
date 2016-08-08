require 'rails_helper'

describe Purl, type: :model do
  it 'indicates when a record is deleted' do
    purl = described_class.create(druid: 'oo000oo0001')
    expect(purl.deleted?).to be_falsey
    purl.deleted_at = Time.zone.now
    purl.save
    expect(purl.deleted?).to be_truthy
  end
end
