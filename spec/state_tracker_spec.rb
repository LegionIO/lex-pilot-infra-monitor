# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::PilotInfraMonitor::StateTracker do
  before { described_class.reset! }

  describe '.update' do
    it 'creates new state on first check' do
      result = described_class.update('http://a.test', :healthy)
      expect(result[:state]).to eq(:healthy)
      expect(result[:changed]).to be true
    end

    it 'does not report change when state stays the same' do
      described_class.update('http://a.test', :healthy)
      result = described_class.update('http://a.test', :healthy)
      expect(result[:changed]).to be false
    end

    it 'reports change when state transitions' do
      described_class.update('http://a.test', :healthy)
      result = described_class.update('http://a.test', :error)
      expect(result[:changed]).to be true
      expect(result[:state]).to eq(:degraded)
    end

    it 'escalates to critical after 3 consecutive failures' do
      described_class.update('http://a.test', :healthy)
      described_class.update('http://a.test', :error)
      described_class.update('http://a.test', :error)
      result = described_class.update('http://a.test', :error)
      expect(result[:state]).to eq(:critical)
    end

    it 'resets consecutive failures on healthy check' do
      described_class.update('http://a.test', :error)
      described_class.update('http://a.test', :error)
      described_class.update('http://a.test', :healthy)
      result = described_class.update('http://a.test', :error)
      expect(result[:state]).to eq(:degraded)
    end
  end

  describe '.state_for' do
    it 'returns :unknown for unchecked URLs' do
      expect(described_class.state_for('http://new.test')).to eq(:unknown)
    end

    it 'returns current state for tracked URLs' do
      described_class.update('http://a.test', :healthy)
      expect(described_class.state_for('http://a.test')).to eq(:healthy)
    end
  end

  describe '.all_states' do
    it 'returns a hash of all tracked URLs and states' do
      described_class.update('http://a.test', :healthy)
      described_class.update('http://b.test', :error)
      states = described_class.all_states
      expect(states.keys).to contain_exactly('http://a.test', 'http://b.test')
      expect(states['http://a.test'][:state]).to eq(:healthy)
      expect(states['http://b.test'][:state]).to eq(:degraded)
    end
  end

  describe 'CheckState' do
    let(:cs) { described_class::CheckState.new('http://x.test') }

    it 'starts in :unknown state' do
      expect(cs.state).to eq(:unknown)
    end

    it 'detects recovery' do
      cs.update(:error)
      cs.update(:healthy)
      expect(cs.recovered?).to be true
    end

    it 'detects worsening' do
      cs.update(:healthy)
      cs.update(:error)
      expect(cs.worsened?).to be true
    end

    it 'tracks duration in state' do
      cs.update(:healthy)
      expect(cs.duration_in_state).to be >= 0
    end
  end
end
