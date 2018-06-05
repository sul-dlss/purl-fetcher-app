require 'rails_helper'

describe ListenerLog do
  context 'without any prior listeners' do
    it 'has no current process' do
      expect(described_class.current).to be_nil
    end
    it 'has no minutes_since_last_active' do
      expect(described_class.minutes_since_last_active).to be_nil
    end
  end
  context 'with a prior inactive listeners' do
    before do
      described_class.create(process_id: 123, started_at: Time.current - 1)
    end
    it 'has current process' do
      expect(described_class.current).to be_an described_class
    end
    it 'has no minutes_since_last_active' do
      expect(described_class.minutes_since_last_active).to be_nil
    end
  end
  context 'with a prior active listeners' do
    before do
      described_class.create(process_id: 123, started_at: Time.current - 1, active_at: Time.current)
    end
    it 'has current process' do
      expect(described_class.current).to be_an described_class
    end
    it 'has minutes_since_last_active' do
      expect(described_class.minutes_since_last_active).to be_an Integer
      expect(described_class.minutes_since_last_active).to be > 0
    end
  end
end
