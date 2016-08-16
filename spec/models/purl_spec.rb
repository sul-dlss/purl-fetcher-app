require 'rails_helper'

describe Purl, type: :model do
  let (:druid) { 'druid:bb050dj7711' }
  describe '.mark_deleted' do
    it 'always starts without deleted_at time' do
      purl = described_class.create(druid: druid)
      expect(purl.deleted_at?).to be_falsey
    end
    it 'marks a record as deleted' do
      expect(described_class.mark_deleted(druid)).to be_truthy
      purl = described_class.find_by_druid(druid)
      expect(purl.deleted_at?).to be_truthy
    end
    it 'marks a record as deleted with a given timestamp' do
      deleted_at_time = Time.current
      expect(described_class.mark_deleted(druid, deleted_at_time)).to be_truthy
      purl = described_class.find_by(druid: druid)
      expect(purl.deleted_at.iso8601).to eq deleted_at_time.iso8601 # favorable compare which removes milliseconds
    end
  end
  describe '.save_from_public_xml' do
    let(:purl_path) { DruidTools::PurlDruid.new(druid, purl_fixture_path).path }
    it 'does not create duplication Collection or relationships' do
      n = 2
      expect do
        n.times do
          described_class.save_from_public_xml(purl_path)
        end
      end.to change{ Collection.all.count }.by(n)
      expect(described_class.find_by_druid(druid).collections.count).to eq n
    end
  end
end
