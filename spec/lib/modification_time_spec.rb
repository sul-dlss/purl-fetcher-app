require 'rails_helper'

describe ModificationTime do
  describe '.get_times' do
    let(:earliest) { '1970-01-01T00:00:00Z' }
    let(:latest) { Fetcher::Y_TEN_K }
    it 'returns the current date and time when time not passed in' do
      expect(described_class.get_times(nil)).to eq(first: earliest, last: latest)
      expect(described_class.get_times({})).to eq(first: earliest, last: latest)
      expect(described_class.get_times(first_modified: nil, last_modified: '01/01/2014')).to eq(first: earliest, last: '2014-01-01T00:00:00Z')
      expect(described_class.get_times(first_modified: '01/01/2014', last_modified: nil)).to eq(first: '2014-01-01T00:00:00Z', last: latest)
    end

    it 'raises an exception if the start date is not before the end date' do
      expect{ described_class.get_times(first_modified: '01/01/2010 10:00:00am', last_modified: '01/01/2009 10:00:00am') }.to raise_error('start time is before end time')
      expect{ described_class.get_times(first_modified: '01/01/2010 10:00:00am', last_modified: '01/01/2010 10:00:00am') }.to raise_error('start time is before end time')
      expect{ described_class.get_times(first_modified: '01/01/2010 10:00:00am', last_modified: '01/01/2010 10:00:01am') }.not_to raise_error
    end

    it 'raises an exception for either starting of ending date in an invalid format' do
      expect{ described_class.get_times(first_modified: '01/01/2010 10:00:00am', last_modified: 'ness') }.to raise_error('invalid time paramaters')
      expect{ described_class.get_times(first_modified: 'bogus', last_modified: '01/01/2010 10:00:00am') }.to raise_error('invalid time paramaters')
      expect{ described_class.get_times(first_modified: 'bogus', last_modified: 'ness') }.to raise_error('invalid time paramaters')
    end

    it 'returns the properly formatted hash for various valid types of input date or time' do
      expected = { first: '2010-01-01T10:00:00Z', last: '2011-01-01T10:00:00Z' }
      inputs = [
        { first_modified: '01/01/2010 10:00:00am',   last_modified: '01/01/2011 10:00:00am UTC' },
        { first_modified: '2010-01-01T02:00:00 PST', last_modified: '01/01/2011 2:00:00am PST' },
        { first_modified: '01/01/2010 10:00:00am',   last_modified: '2011-01-01T10:00:00Z' }
      ]
      inputs.each do |input|
        expect(described_class.get_times(input)).to eq(expected)
      end
      expect(described_class.get_times(first_modified: '01/01/2010', last_modified: '2011-01-01T18:00:00Z')).to eq(first: '2010-01-01T00:00:00Z', last: '2011-01-01T18:00:00Z')
      expect(described_class.get_times(first_modified: '2011-01-01T18:00:00Z', last_modified: '2014-12-01')).to eq(first: '2011-01-01T18:00:00Z', last: '2014-12-01T00:00:00Z')
      expect(described_class.get_times(first_modified: 'January 1, 2009', last_modified: '2012-01-01T18:00:00Z')).to eq(first: '2009-01-01T00:00:00Z', last: '2012-01-01T18:00:00Z')
    end
  end
end
