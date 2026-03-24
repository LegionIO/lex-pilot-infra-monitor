# frozen_string_literal: true

require_relative 'pilot_infra_monitor/version'
require_relative 'pilot_infra_monitor/state_tracker'
require_relative 'pilot_infra_monitor/alert_dedup'
require_relative 'pilot_infra_monitor/helpers/settings'
require_relative 'pilot_infra_monitor/runners/health_checker'

module Legion
  module Extensions
    module PilotInfraMonitor
    end
  end
end
