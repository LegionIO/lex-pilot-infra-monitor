# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::PilotInfraMonitor::Helpers::EventPublisher do
  describe '.publish_transition' do
    context 'when Legion::Events is available' do
      before do
        stub_const('Legion::Events', double('Events'))
        allow(Legion::Events).to receive(:emit)
      end

      it 'emits a health.state_change event' do
        described_class.publish_transition(
          url: 'https://vault.example.com', from: :healthy, to: :critical
        )
        expect(Legion::Events).to have_received(:emit).with(
          'health.state_change',
          hash_including(url: 'https://vault.example.com', from: :healthy, to: :critical)
        )
      end
    end

    context 'when Legion::Events is not available' do
      it 'does not raise' do
        expect do
          described_class.publish_transition(url: 'https://x.com', from: :healthy, to: :critical)
        end.not_to raise_error
      end
    end
  end
end
