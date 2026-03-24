# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::PilotInfraMonitor::Helpers::Settings do
  describe '.endpoints' do
    context 'when settings are configured' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:pilot_infra_monitor).and_return(
          { endpoints: [{ url: 'https://vault.example.com/v1/sys/health', type: 'vault' }],
            webhook: 'https://hooks.slack.com/test' }
        )
      end

      it 'returns configured endpoint URLs' do
        expect(described_class.endpoints).to eq(['https://vault.example.com/v1/sys/health'])
      end

      it 'returns the configured webhook' do
        expect(described_class.webhook).to eq('https://hooks.slack.com/test')
      end
    end

    context 'when settings are not configured' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:pilot_infra_monitor).and_return(nil)
      end

      it 'returns empty array' do
        expect(described_class.endpoints).to eq([])
      end

      it 'returns nil webhook' do
        expect(described_class.webhook).to be_nil
      end
    end
  end
end
