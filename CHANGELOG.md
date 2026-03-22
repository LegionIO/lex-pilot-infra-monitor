# Changelog

## [0.1.0] - 2026-03-21

### Added
- `Runners::HealthChecker` with `check_endpoints` and `alert_unhealthy` methods
- HTTP health check polling with configurable timeout
- Slack webhook alert delivery for unhealthy endpoints
- `Actor::Monitor` interval actor (60s polling)
- Full RSpec test coverage (17 specs)
