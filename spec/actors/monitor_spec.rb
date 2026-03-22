# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/pilot_infra_monitor/actors/monitor'

RSpec.describe Legion::Extensions::PilotInfraMonitor::Actor::Monitor do
  subject(:actor) { described_class.allocate }

  describe '#runner_class' do
    it 'returns the health checker runner class string' do
      expect(actor.runner_class).to eq('Legion::Extensions::PilotInfraMonitor::Runners::HealthChecker')
    end
  end

  describe '#runner_function' do
    it 'returns check_endpoints' do
      expect(actor.runner_function).to eq('check_endpoints')
    end
  end

  describe '#time' do
    it 'returns 60 (once per minute)' do
      expect(actor.time).to eq(60)
    end
  end

  describe '#run_now?' do
    it 'returns false' do
      expect(actor.run_now?).to be false
    end
  end

  describe '#use_runner?' do
    it 'returns false' do
      expect(actor.use_runner?).to be false
    end
  end

  describe '#check_subtask?' do
    it 'returns false' do
      expect(actor.check_subtask?).to be false
    end
  end

  describe '#generate_task?' do
    it 'returns false' do
      expect(actor.generate_task?).to be false
    end
  end
end
