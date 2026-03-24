# frozen_string_literal: true

require 'net/http'

module Legion
  module Extensions
    module PilotInfraMonitor
      module Runners
        module HealthChecker
          def check_endpoints(urls: nil, endpoint_configs: nil, timeout: 5)
            configs = endpoint_configs || Helpers::Settings.endpoint_configs
            configs = urls.map { |u| { url: u } } if configs.empty? && urls
            configs ||= []
            return { total: 0, healthy: 0, unhealthy: 0, results: [], alert_needed: false, transitions: [] } if configs.empty?

            results = configs.map { |cfg| check_single_config(cfg, timeout) }
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
            webhook ||= Helpers::Settings.webhook
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
            results.select do |r|
              next false if r[:status] == :healthy

              check_state = StateTracker.check_state_for(r[:url])
              worsened = check_state&.worsened? || false
              AlertDedup.should_alert?(r[:url], r[:status], worsened: worsened)
            end
          end

          def build_alert_message(alertable)
            details = alertable.map do |r|
              state = StateTracker.state_for(r[:url])
              "  #{r[:url]}: #{state} (#{r[:error] || r[:code]})"
            end.join("\n")
            "Health check alert:\n#{details}"
          end

          def check_single_config(config, timeout)
            url = config.is_a?(Hash) ? config[:url] : config.to_s
            endpoint_type = config.is_a?(Hash) ? config[:type] : nil
            result = check_single(url, timeout)
            return result if result[:status] == :error
            return result unless endpoint_type

            semantic_status = Helpers::SemanticChecker.classify(
              type: endpoint_type,
              status_code: result[:code],
              body: result.fetch(:body, '')
            )
            result.merge(status: semantic_status)
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
            { url: url, status: healthy ? :healthy : :unhealthy, code: response.code.to_i, body: response.body.to_s }
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
