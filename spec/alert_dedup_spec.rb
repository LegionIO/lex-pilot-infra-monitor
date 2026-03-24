# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::PilotInfraMonitor::AlertDedup do
  before { described_class.reset! }

  describe '.should_alert?' do
    it 'allows first alert for a URL' do
      expect(described_class.should_alert?('http://a.test', :degraded)).to be true
    end

    it 'suppresses re-alert within suppression window for same state' do
      described_class.record_alert('http://a.test', :degraded)
      expect(described_class.should_alert?('http://a.test', :degraded)).to be false
    end

    it 'allows alert when state worsens even within suppression window' do
      described_class.record_alert('http://a.test', :degraded)
      expect(described_class.should_alert?('http://a.test', :critical, worsened: true)).to be true
    end

    it 'allows re-alert after suppression window expires' do
      described_class.record_alert('http://a.test', :degraded)
      # Simulate time passing by backdating the record
      described_class.instance_variable_get(:@last_alert)['http://a.test'][:time] =
        Time.now - described_class::REALERT_SUPPRESSION - 1
      expect(described_class.should_alert?('http://a.test', :degraded)).to be true
    end

    it 'allows alert for different state after suppression' do
      described_class.record_alert('http://a.test', :degraded)
      described_class.instance_variable_get(:@last_alert)['http://a.test'][:time] =
        Time.now - described_class::REALERT_SUPPRESSION - 1
      expect(described_class.should_alert?('http://a.test', :critical)).to be true
    end
  end

  describe '.record_alert' do
    it 'stores alert timestamp and state' do
      described_class.record_alert('http://a.test', :critical)
      expect(described_class.pending_count).to eq(1)
    end
  end

  describe '.correlate' do
    it 'groups transitions by state' do
      transitions = [
        double(state: :degraded, url: 'http://a.test'),
        double(state: :critical, url: 'http://b.test'),
        double(state: :degraded, url: 'http://c.test')
      ]
      grouped = described_class.correlate(transitions)
      expect(grouped[:degraded]).to eq(['http://a.test', 'http://c.test'])
      expect(grouped[:critical]).to eq(['http://b.test'])
    end
  end

  describe 'constants' do
    it 'has a 30-second correlation window' do
      expect(described_class::CORRELATION_WINDOW).to eq(30)
    end

    it 'has a 600-second re-alert suppression' do
      expect(described_class::REALERT_SUPPRESSION).to eq(600)
    end
  end
end
