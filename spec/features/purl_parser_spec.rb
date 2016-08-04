require 'rails_helper'

describe PurlParser do
  describe('bb050dj7711') do
    let(:sample_doc_path) { DruidTools::PurlDruid.new('bb050dj7711', purl_fixture_path).path }
    let(:purl) { described_class.new(sample_doc_path) }

    it 'gets the title from the mods file' do
      expect(purl.title).to eq("This is Pete's New Test title for this object.")
    end

    it 'gets the druid from publicMetadata' do
      expect(purl.druid).to match('druid:bb050dj7711')
    end

    it 'gets true and false data from the public xml regarding release status' do
      expect(purl.releases).to match(false: ['Atago'], true: ['CARRICKR-TEST', 'Robot_Testing_Feb_5_2015'])
    end

    it 'gets the object type' do
      expect(purl.object_type).to match('item')
    end

    it 'gets the collections the object is a member of' do
      expect(purl.collections).to match(['druid:nt028fd5773', 'druid:wn860zc7322'])
    end

    it 'returns empty string when no cat key is present' do
      expect(purl.catkey).to match('')
    end
  end

  describe('ct961sj2730') do
    let(:sample_doc_path) { DruidTools::PurlDruid.new('ct961sj2730', purl_fixture_path).path }
    let(:purl) { described_class.new(sample_doc_path) }

    it 'gets the cat key when one is present' do
      expect(purl.catkey).to match('10357851')
    end

    it 'gets multiple object types when an object has multiple types' do
      expect(purl.object_type).to match('collection|set')
    end
  end
end
