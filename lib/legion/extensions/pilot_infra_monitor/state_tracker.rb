# frozen_string_literal: true

module Legion
  module Extensions
    module PilotInfraMonitor
      module StateTracker
        STATES = %i[healthy degraded critical unknown].freeze
        SEVERITY = { healthy: 0, degraded: 1, critical: 2, unknown: 1 }.freeze

        class CheckState
          attr_reader :url, :state, :previous_state, :changed_at, :last_checked_at, :consecutive_failures

          def initialize(url)
            @url = url
            @state = :unknown
            @previous_state = :unknown
            @changed_at = Time.now
            @last_checked_at = nil
            @consecutive_failures = 0
          end

          def update(new_state)
            @last_checked_at = Time.now
            @previous_state = @state

            case new_state
            when :healthy
              @consecutive_failures = 0
            else
              @consecutive_failures += 1
            end

            effective = effective_state(new_state)
            if effective == @state
              false
            else
              @state = effective
              @changed_at = Time.now
              true
            end
          end

          def transition?
            @state != @previous_state
          end

          def worsened?
            SEVERITY.fetch(@state, 0) > SEVERITY.fetch(@previous_state, 0)
          end

          def recovered?
            @previous_state != :healthy && @state == :healthy
          end

          def duration_in_state
            Time.now - @changed_at
          end

          private

          def effective_state(raw_state)
            case raw_state
            when :healthy then :healthy
            when :error   then @consecutive_failures >= 3 ? :critical : :degraded
            else               :degraded
            end
          end
        end

        class << self
          def tracker
            @tracker ||= {}
            @mutex ||= Mutex.new
            @tracker
          end

          def mutex
            @mutex ||= Mutex.new
          end

          def update(url, raw_state)
            mutex.synchronize do
              tracker[url] ||= CheckState.new(url)
              changed = tracker[url].update(raw_state)
              { url: url, state: tracker[url].state, changed: changed, check_state: tracker[url] }
            end
          end

          def state_for(url)
            mutex.synchronize { tracker[url]&.state || :unknown }
          end

          def all_states
            mutex.synchronize do
              tracker.transform_values { |cs| { state: cs.state, since: cs.changed_at, failures: cs.consecutive_failures } }
            end
          end

          def transitions_since(cutoff)
            mutex.synchronize do
              tracker.values.select { |cs| cs.changed_at >= cutoff && cs.transition? }
            end
          end

          def reset!
            mutex.synchronize { tracker.clear }
          end
        end
      end
    end
  end
end
