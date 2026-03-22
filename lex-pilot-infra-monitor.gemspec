# frozen_string_literal: true

require_relative 'lib/legion/extensions/pilot_infra_monitor/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-pilot-infra-monitor'
  spec.version       = Legion::Extensions::PilotInfraMonitor::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX::PilotInfraMonitor'
  spec.description   = 'Infrastructure health check monitoring with alert delivery for LegionIO'
  spec.homepage      = 'https://github.com/LegionIO'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']
end
