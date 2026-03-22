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

            {
              total: results.size,
              healthy: results.count { |r| r[:status] == :healthy },
              unhealthy: unhealthy.size,
              results: results,
              alert_needed: unhealthy.any?
            }
          end

          def alert_unhealthy(results:, webhook: nil)
            unhealthy = results.reject { |r| r[:status] == :healthy }
            return nil if unhealthy.empty?

            details = unhealthy.map do |r|
              "  #{r[:url]}: #{r[:status]} (#{r[:error] || r[:code]})"
            end.join("\n")
            message = "Health check alert:\n#{details}"

            send_webhook(webhook, message) if webhook

            { alerted: true, webhook: webhook, count: unhealthy.size, message: message }
          end

          private

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
