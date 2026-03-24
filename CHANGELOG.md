# Changelog

## [0.2.0] - 2026-03-24

### Added
- `StateTracker` module: per-URL state machine (healthy/degraded/critical/unknown) with transition detection, consecutive failure escalation (3 failures -> critical), and recovery tracking
- `AlertDedup` module: 30-second correlation window, 10-minute re-alert suppression per URL, worsened-state bypass, and alert grouping via `correlate`
- `alert_recoveries` runner method: generates recovery messages with previous state and duration
- `health_states` runner method: returns all tracked URL states
- State tracking integrated into `check_endpoints` — returns `transitions` array alongside existing results
- Alert deduplication integrated into `alert_unhealthy` — suppresses duplicate alerts within suppression window

### Changed
- `alert_unhealthy` now filters through AlertDedup before sending alerts; extracted `filter_alertable` and `build_alert_message` private methods

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
