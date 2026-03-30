# frozen_string_literal: true

module Legion
  module Extensions
    module PilotInfraMonitor
      module Helpers
        module Settings
          module_function

          def config
            return {} unless defined?(Legion::Settings)

            Legion::Settings[:pilot_infra_monitor] || {}
          end

          def endpoints
            entries = config[:endpoints] || []
            entries.filter_map { |e| e.is_a?(Hash) ? e[:url] : e.to_s }
          end

          def endpoint_configs
            config[:endpoints] || []
          end

          def webhook
            config[:webhook]
          end

          def check_interval
            config[:check_interval] || 60
          end
        end
      end
    end
  end
end
