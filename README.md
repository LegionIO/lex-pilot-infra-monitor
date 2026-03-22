# lex-pilot-infra-monitor

Infrastructure health check monitoring with alert delivery for LegionIO.

## Usage

```ruby
checker = Class.new { include Legion::Extensions::PilotInfraMonitor::Runners::HealthChecker }.new

# Check multiple endpoints
result = checker.check_endpoints(urls: ['http://consul:8500/v1/status/leader', 'http://vault:8200/v1/sys/health'])
# => { total: 2, healthy: 1, unhealthy: 1, results: [...], alert_needed: true }

# Send alerts for unhealthy endpoints
checker.alert_unhealthy(results: result[:results], webhook: '/services/T/B/x')
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```
