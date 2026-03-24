# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::PilotInfraMonitor::Helpers::CheckHistory do
  before { described_class.reset! }

  describe '.record' do
    it 'stores a check result' do
      described_class.record(url: 'https://example.com', state: :healthy, timestamp: Time.now)
      expect(described_class.history_for('https://example.com').size).to eq(1)
    end
  end

  describe '.open_alert' do
    it 'records alert open time' do
      described_class.open_alert(url: 'https://example.com', state: :critical, timestamp: Time.now)
      expect(described_class.open_alerts.size).to eq(1)
    end
  end

  describe '.close_alert' do
    it 'records recovery and computes duration' do
      opened_at = Time.now - 300
      described_class.open_alert(url: 'https://example.com', state: :critical, timestamp: opened_at)
      result = described_class.close_alert(url: 'https://example.com', timestamp: Time.now)
      expect(result[:duration]).to be_within(5).of(300)
    end
  end

  describe '.mttr' do
    it 'computes mean time to recovery' do
      t = Time.now
      described_class.open_alert(url: 'https://a.com', state: :critical, timestamp: t - 600)
      described_class.close_alert(url: 'https://a.com', timestamp: t - 300)
      described_class.open_alert(url: 'https://b.com', state: :degraded, timestamp: t - 400)
      described_class.close_alert(url: 'https://b.com', timestamp: t - 200)

      expect(described_class.mttr).to be_within(5).of(250) # (300 + 200) / 2
    end

    it 'returns nil when no resolved alerts' do
      expect(described_class.mttr).to be_nil
    end
  end
end
