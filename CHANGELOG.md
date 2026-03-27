# Changelog

## [0.2.4] - 2026-03-27

### Fixed
- `Runners::HealthChecker#send_webhook`: replaced `Legion::Logging.logger&.error` with `log.error` via private `log` helper to satisfy Helper Migration and Rescue Logging CI lint rules
- `Helpers::SemanticChecker#check_consul`: replaced `Legion::JSON.load` with `json_load` helper and `Legion::Logging.logger&.error` with `log.error` via private `log` helper
- `Helpers::EventPublisher#publish_transition`: replaced `Legion::Logging::Logger.warn` with `log.warn` via private `log` helper

## [0.2.3] - 2026-03-27

### Fixed
- `Helpers::SemanticChecker#check_consul`: bare `rescue StandardError` now captures exception as `=> e` and logs via `Legion::Logging.logger`
- `Runners::HealthChecker#send_webhook`: bare `rescue StandardError` now captures exception as `=> e` and logs via `Legion::Logging.logger`

## [0.2.2] - 2026-03-27

### Fixed
- HealthChecker runner: added `extend self` so methods are callable as module methods by the actor framework

## [0.2.1] - 2026-03-24

### Fixed
- Version bump to trigger gem release (0.2.0 CI did not publish)

## [0.2.0] - 2026-03-24

### Added
- `StateTracker` module: per-URL state machine (healthy/degraded/critical/unknown) with transition detection, consecutive failure escalation (3 failures -> critical), and recovery tracking
- `AlertDedup` module: 30-second correlation window, 10-minute re-alert suppression per URL, worsened-state bypass, and alert grouping via `correlate`
- `alert_recoveries` runner method: generates recovery messages with previous state and duration
- `health_states` runner method: returns all tracked URL states
- State tracking integrated into `check_endpoints` — returns `transitions` array alongside existing results
- Alert deduplication integrated into `alert_unhealthy` — suppresses duplicate alerts within suppression window
- Settings-driven endpoint configuration via `Legion::Settings[:pilot_infra_monitor]`
- Semantic health checks for Consul, Vault, and Nomad APIs (`Helpers::SemanticChecker`)
- Check history persistence and MTTR tracking (`Helpers::CheckHistory`)
- AMQP event publishing on state transitions via `Legion::Events` (`Helpers::EventPublisher`)

### Fixed
- Worsened flag now passed through alert pipeline to bypass suppression window

### Changed
- `alert_unhealthy` now filters through AlertDedup before sending alerts; extracted `filter_alertable` and `build_alert_message` private methods
- `check_endpoints` accepts `endpoint_configs:` for type-aware semantic health checking; `urls:` remains for backward compatibility

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
