require 'rails_helper'

describe Purl, type: :model do
  it 'indicates when a record is deleted' do
    purl = described_class.create(druid: 'oo000oo0001')
    expect(purl.deleted_at?).to be_falsey
    purl.deleted_at = Time.zone.now
    purl.save
    expect(purl.deleted_at?).to be_truthy
  end
  describe '.save_from_public_xml' do
    let(:druid_path) { DruidTools::PurlDruid.new('bb050dj6667', purl_fixture_path).path }
    it 'does not create duplication Collection or relationships' do
      expect do
        described_class.save_from_public_xml(sample_doc_path)
        described_class.save_from_public_xml(sample_doc_path)
      end.to change{ Collection.all.count }.by(2)
      expect(described_class.find_by_druid('druid:bb050dj7711').collections.count).to eq 2
    end
  end
end
