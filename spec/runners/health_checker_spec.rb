# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::PilotInfraMonitor::Runners::HealthChecker do
  let(:checker) { Class.new { include Legion::Extensions::PilotInfraMonitor::Runners::HealthChecker }.new }

  describe '#check_endpoints' do
    context 'when urls list is empty' do
      it 'returns zero totals and no alert needed' do
        result = checker.check_endpoints(urls: [])
        expect(result[:total]).to eq(0)
        expect(result[:healthy]).to eq(0)
        expect(result[:unhealthy]).to eq(0)
        expect(result[:alert_needed]).to be false
      end
    end

    context 'when all endpoints are healthy' do
      before do
        allow(checker).to receive(:check_single).and_return(
          { url: 'http://good.test', status: :healthy, code: 200 }
        )
      end

      it 'returns all healthy and no alert needed' do
        result = checker.check_endpoints(urls: ['http://good.test'])
        expect(result[:total]).to eq(1)
        expect(result[:healthy]).to eq(1)
        expect(result[:unhealthy]).to eq(0)
        expect(result[:alert_needed]).to be false
      end
    end

    context 'when an endpoint is unhealthy' do
      before do
        allow(checker).to receive(:check_single).and_return(
          { url: 'http://bad.test', status: :error, error: 'connection refused' }
        )
      end

      it 'detects unhealthy endpoints and sets alert_needed' do
        result = checker.check_endpoints(urls: ['http://bad.test'])
        expect(result[:unhealthy]).to eq(1)
        expect(result[:alert_needed]).to be true
      end

      it 'includes results array with each check' do
        result = checker.check_endpoints(urls: ['http://bad.test'])
        expect(result[:results]).to be_an(Array)
        expect(result[:results].first[:status]).to eq(:error)
      end
    end

    context 'with mixed healthy and unhealthy endpoints' do
      before do
        allow(checker).to receive(:check_single).with('http://good.test', anything).and_return(
          { url: 'http://good.test', status: :healthy, code: 200 }
        )
        allow(checker).to receive(:check_single).with('http://bad.test', anything).and_return(
          { url: 'http://bad.test', status: :error, error: 'timeout' }
        )
      end

      it 'counts healthy and unhealthy separately' do
        result = checker.check_endpoints(urls: ['http://good.test', 'http://bad.test'])
        expect(result[:total]).to eq(2)
        expect(result[:healthy]).to eq(1)
        expect(result[:unhealthy]).to eq(1)
        expect(result[:alert_needed]).to be true
      end
    end
  end

  describe '#alert_unhealthy' do
    context 'when no unhealthy results' do
      it 'returns nil' do
        expect(checker.alert_unhealthy(results: [])).to be_nil
      end

      it 'returns nil for healthy-only results' do
        results = [{ url: 'http://good.test', status: :healthy, code: 200 }]
        expect(checker.alert_unhealthy(results: results)).to be_nil
      end
    end

    context 'when unhealthy results present' do
      let(:results) do
        [{ url: 'http://bad.test', status: :error, error: 'timeout' }]
      end

      it 'returns alerted true with count' do
        result = checker.alert_unhealthy(results: results, webhook: '/services/T/B/x')
        expect(result[:alerted]).to be true
        expect(result[:count]).to eq(1)
      end

      it 'builds a message with endpoint details' do
        result = checker.alert_unhealthy(results: results)
        expect(result[:message]).to include('http://bad.test')
        expect(result[:message]).to include('timeout')
      end
    end

    context 'with multiple unhealthy results' do
      let(:results) do
        [
          { url: 'http://a.test', status: :error, error: 'connection refused' },
          { url: 'http://b.test', status: :unhealthy, code: 503 }
        ]
      end

      it 'counts all unhealthy endpoints' do
        result = checker.alert_unhealthy(results: results)
        expect(result[:count]).to eq(2)
      end
    end
  end
end
