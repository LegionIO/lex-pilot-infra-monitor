# Changelog

## [0.1.1] - 2026-03-22

### Changed
- Add legion-logging, legion-settings, legion-json, legion-cache, legion-crypt, legion-data, and legion-transport as runtime dependencies
- Update spec_helper with real sub-gem helper stubs replacing manual Legion::Logging, Legion::Extensions::Core, and Legion::Settings stubs

## [0.1.0] - 2026-03-21

### Added
- `Runners::HealthChecker` with `check_endpoints` and `alert_unhealthy` methods
- HTTP health check polling with configurable timeout
- Slack webhook alert delivery for unhealthy endpoints
- `Actor::Monitor` interval actor (60s polling)
- Full RSpec test coverage (17 specs)
