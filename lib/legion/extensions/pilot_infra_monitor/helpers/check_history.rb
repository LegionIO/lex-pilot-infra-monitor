# frozen_string_literal: true

module Legion
  module Extensions
    module PilotInfraMonitor
      module Helpers
        module CheckHistory
          @mutex = Mutex.new
          @history = {}
          @open_alerts = {}
          @resolved_alerts = []

          module_function

          def record(url:, state:, timestamp: Time.now)
            @mutex.synchronize do
              (@history[url] ||= []) << { state: state, timestamp: timestamp }
              @history[url].shift while @history[url].size > 1000
            end
          end

          def history_for(url)
            @mutex.synchronize { (@history[url] || []).dup }
          end

          def open_alert(url:, state:, timestamp: Time.now)
            @mutex.synchronize do
              @open_alerts[url] = { state: state, opened_at: timestamp }
            end
          end

          def close_alert(url:, timestamp: Time.now)
            @mutex.synchronize do
              alert = @open_alerts.delete(url)
              return nil unless alert

              duration = timestamp - alert[:opened_at]
              entry = { url: url, state: alert[:state], opened_at: alert[:opened_at],
                        closed_at: timestamp, duration: duration }
              @resolved_alerts << entry
              entry
            end
          end

          def open_alerts
            @mutex.synchronize { @open_alerts.dup }
          end

          def mttr
            @mutex.synchronize do
              return nil if @resolved_alerts.empty?

              total = @resolved_alerts.sum { |a| a[:duration] }
              total.to_f / @resolved_alerts.size
            end
          end

          def reset!
            @mutex.synchronize do
              @history.clear
              @open_alerts.clear
              @resolved_alerts.clear
            end
          end
        end
      end
    end
  end
end
