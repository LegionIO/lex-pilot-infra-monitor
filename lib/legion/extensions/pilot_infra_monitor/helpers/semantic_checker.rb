# frozen_string_literal: true

module Legion
  module Extensions
    module PilotInfraMonitor
      module Helpers
        module SemanticChecker
          VAULT_STATUS = {
            200 => :healthy,   # active
            429 => :degraded,  # standby
            472 => :degraded,  # DR secondary
            473 => :degraded,  # performance standby
            501 => :critical,  # uninitialized
            503 => :critical   # sealed
          }.freeze

          module_function

          def classify(type:, status_code:, body: '')
            case type.to_s
            when 'vault'  then check_vault(status_code: status_code, body: body)
            when 'consul' then check_consul(status_code: status_code, body: body)
            when 'nomad'  then check_nomad(status_code: status_code, body: body)
            else
              status_code < 400 ? :healthy : :unhealthy
            end
          end

          def check_vault(status_code:, body: '')
            VAULT_STATUS.fetch(status_code, :critical)
          end

          def check_consul(status_code:, body: '')
            return :critical unless status_code < 400

            entries = begin
              Legion::JSON.load(body)
            rescue StandardError
              []
            end
            return :healthy unless entries.is_a?(Array) && entries.any?

            :degraded
          end

          def check_nomad(status_code:, body: '')
            status_code == 200 ? :healthy : :critical
          end
        end
      end
    end
  end
end
