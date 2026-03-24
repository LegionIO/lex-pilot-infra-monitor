# frozen_string_literal: true

require 'net/http'

module Legion
  module Extensions
    module PilotInfraMonitor
      module Runners
        module HealthChecker
          def check_endpoints(urls:, timeout: 5)
            results = urls.map { |url| check_single(url, timeout) }
            unhealthy = results.reject { |r| r[:status] == :healthy }

            state_updates = results.map { |r| StateTracker.update(r[:url], r[:status]) }
            transitions = state_updates.select { |u| u[:changed] }

            {
              total: results.size,
              healthy: results.count { |r| r[:status] == :healthy },
              unhealthy: unhealthy.size,
              results: results,
              alert_needed: unhealthy.any?,
              transitions: transitions.map { |t| { url: t[:url], state: t[:state] } }
            }
          end

          def alert_unhealthy(results:, webhook: nil)
            alertable = filter_alertable(results)
            return nil if alertable.empty?

            message = build_alert_message(alertable)
            alertable.each { |r| AlertDedup.record_alert(r[:url], StateTracker.state_for(r[:url])) }
            send_webhook(webhook, message) if webhook

            { alerted: true, webhook: webhook, count: alertable.size, message: message }
          end

          def alert_recoveries(transitions:, webhook: nil)
            recovered = transitions.select { |t| t[:state] == :healthy }
            return nil if recovered.empty?

            details = recovered.map do |t|
              cs = t[:check_state]
              duration = cs.respond_to?(:duration_in_state) ? cs.duration_in_state.round : 0
              "  #{t[:url]}: recovered (was #{cs.previous_state} for #{duration}s)"
            end.join("\n")
            message = "Recovery:\n#{details}"

            send_webhook(webhook, message) if webhook

            { recovered: true, count: recovered.size, message: message }
          end

          def health_states
            StateTracker.all_states
          end

          private

          def filter_alertable(results)
            unhealthy = results.reject { |r| r[:status] == :healthy }
            return [] if unhealthy.empty?

            unhealthy.select do |r|
              state = StateTracker.state_for(r[:url])
              AlertDedup.should_alert?(r[:url], state)
            end
          end

          def build_alert_message(alertable)
            details = alertable.map do |r|
              state = StateTracker.state_for(r[:url])
              "  #{r[:url]}: #{state} (#{r[:error] || r[:code]})"
            end.join("\n")
            "Health check alert:\n#{details}"
          end

          def check_single(url, timeout)
            uri = URI(url)
            response = Net::HTTP.start(
              uri.host, uri.port,
              use_ssl: uri.scheme == 'https',
              open_timeout: timeout,
              read_timeout: timeout
            ) { |http| http.get(uri.path.empty? ? '/' : uri.path) }

            healthy = response.code.to_i < 400
            { url: url, status: healthy ? :healthy : :unhealthy, code: response.code.to_i }
          rescue StandardError => e
            { url: url, status: :error, error: e.message }
          end

          def send_webhook(webhook, message)
            return unless defined?(Legion::Extensions::Slack::Client)

            Legion::Extensions::Slack::Client.new.send_webhook(
              webhook: webhook, text: message
            )
          rescue StandardError
            nil
          end
        end
      end
    end
  end
end
