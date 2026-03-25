# lex-pilot-infra-monitor

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Infrastructure health check monitoring pilot extension for LegionIO. Polls configured HTTP endpoints every 60 seconds, classifies responses as healthy/unhealthy/error, and delivers alerts via Slack webhook when unhealthy endpoints are detected.

## Gem Info

- **Gem name**: `lex-pilot-infra-monitor`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::PilotInfraMonitor`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/pilot_infra_monitor/
  version.rb
  runners/
    health_checker.rb  # check_endpoints(urls:, timeout:), alert_unhealthy(results:, webhook:)
  actors/
    monitor.rb         # Every 60s actor that calls check_endpoints
spec/
  runners/
    health_checker_spec.rb
  actors/
    monitor_spec.rb
```

## Runner: `Runners::HealthChecker`

### `check_endpoints(urls:, timeout: 5)`

Makes HTTP GET requests to each URL using `Net::HTTP`. A response with HTTP status < 400 is `:healthy`; >= 400 is `:unhealthy`; connection errors are `:error`.

Returns:
```ruby
{
  total: N,
  healthy: N,
  unhealthy: N,
  results: [{ url:, status:, code: } | { url:, status: :error, error: }],
  alert_needed: true | false
}
```

### `alert_unhealthy(results:, webhook: nil)`

Filters unhealthy/error results and formats a text message. If `webhook` is provided and `lex-slack` is loaded, calls `Legion::Extensions::Slack::Client.new.send_webhook`.

Returns `nil` if no unhealthy endpoints, otherwise `{ alerted:, webhook:, count:, message: }`.

## Actor: `Actor::Monitor`

`Every 60s`. Calls `check_endpoints`. `run_now?` is false — waits for first interval.

## Integration Points

- **lex-slack** (`extensions-other/`): alert delivery via `send_webhook` (optional — skipped if not loaded)

## Development Notes

- Uses stdlib `Net::HTTP` only — no Faraday dependency
- SSL is auto-detected from URI scheme (`https://` triggers `use_ssl: true`)
- `timeout` applies to both `open_timeout` and `read_timeout`
- This is a pilot extension — production monitoring should use a dedicated observability stack
