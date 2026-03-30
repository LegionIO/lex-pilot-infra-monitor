# frozen_string_literal: true

module Legion
  module Extensions
    module PilotInfraMonitor
      module Actor
        class Monitor < Legion::Extensions::Actors::Every # rubocop:disable Legion/Extension/EveryActorRequiresTime
          def runner_class
            'Legion::Extensions::PilotInfraMonitor::Runners::HealthChecker'
          end

          def runner_function
            'check_endpoints'
          end

          def time
            60
          end

          def run_now?
            false
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
