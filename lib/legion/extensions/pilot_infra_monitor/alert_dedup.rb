# frozen_string_literal: true

module Legion
  module Extensions
    module PilotInfraMonitor
      module AlertDedup
        CORRELATION_WINDOW = 30
        REALERT_SUPPRESSION = 600

        class << self
          def should_alert?(url, state, worsened: false)
            mutex.synchronize do
              now = Time.now
              key = url.to_s

              last = last_alert[key]
              return true if last.nil?

              elapsed = now - last[:time]

              return true if worsened
              return false if elapsed < REALERT_SUPPRESSION && last[:state] == state

              true
            end
          end

          def record_alert(url, state)
            mutex.synchronize do
              last_alert[url.to_s] = { time: Time.now, state: state }
            end
          end

          def correlate(transitions)
            grouped = transitions.group_by(&:state)
            grouped.transform_values { |checks| checks.map(&:url) }
          end

          def pending_count
            mutex.synchronize { last_alert.size }
          end

          def reset!
            mutex.synchronize { last_alert.clear }
          end

          private

          def last_alert
            @last_alert ||= {}
          end

          def mutex
            @mutex ||= Mutex.new
          end
        end
      end
    end
  end
end
