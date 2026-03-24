# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::PilotInfraMonitor::Helpers::SemanticChecker do
  describe '.check_vault' do
    it 'returns healthy for 200 (active)' do
      expect(described_class.check_vault(status_code: 200, body: '{}')).to eq(:healthy)
    end

    it 'returns degraded for 429 (standby)' do
      expect(described_class.check_vault(status_code: 429, body: '{}')).to eq(:degraded)
    end

    it 'returns critical for 501 (uninitialized)' do
      expect(described_class.check_vault(status_code: 501, body: '{}')).to eq(:critical)
    end

    it 'returns critical for 503 (sealed)' do
      expect(described_class.check_vault(status_code: 503, body: '{}')).to eq(:critical)
    end
  end

  describe '.check_consul' do
    it 'returns healthy when no critical services' do
      body = '[]'
      expect(described_class.check_consul(status_code: 200, body: body)).to eq(:healthy)
    end

    it 'returns degraded when critical services exist' do
      body = '[{"ServiceName":"web","Status":"critical"}]'
      expect(described_class.check_consul(status_code: 200, body: body)).to eq(:degraded)
    end
  end

  describe '.check_nomad' do
    it 'returns healthy for 200' do
      expect(described_class.check_nomad(status_code: 200, body: '{}')).to eq(:healthy)
    end

    it 'returns critical for non-200' do
      expect(described_class.check_nomad(status_code: 500, body: '{}')).to eq(:critical)
    end
  end

  describe '.classify' do
    it 'dispatches to vault checker for vault type' do
      expect(described_class.classify(type: 'vault', status_code: 429, body: '{}')).to eq(:degraded)
    end

    it 'falls back to HTTP status for unknown type' do
      expect(described_class.classify(type: 'http', status_code: 200, body: '')).to eq(:healthy)
    end
  end
end
