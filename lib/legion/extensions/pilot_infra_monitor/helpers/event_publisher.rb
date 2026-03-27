# frozen_string_literal: true

module Legion
  module Extensions
    module PilotInfraMonitor
      module Helpers
        module EventPublisher
          module_function

          def publish_transition(url:, from:, to:, timestamp: Time.now)
            return unless defined?(Legion::Events)

            Legion::Events.emit('health.state_change',
                                url: url, from: from, to: to, timestamp: timestamp)
          rescue StandardError => e
            log.warn("Failed to publish health event: #{e.message}")
          end

          def log
            return Legion::Logging if defined?(Legion::Logging)

            @log ||= Object.new.tap do |nl|
              %i[debug info warn error fatal].each { |m| nl.define_singleton_method(m) { |*| nil } }
            end
          end
        end
      end
    end
  end
end
