require "active_support/core_ext/array/conversions"
require "active_support/dependencies/autoload"
require "active_support/core_ext/kernel/singleton_class"
require "active_support/core_ext/module/aliasing"
require "ahn-components/version"
require "adhearsion/components"

class AhnComponents < Adhearsion::Plugin

  init :ahn_components do
    logger.warn "Using deprecated components subsystem"

    components_directory = File.expand_path "components"

    if File.directory? components_directory
      Adhearsion::Components.component_manager = Adhearsion::Components::ComponentManager.new components_directory
      Kernel.send(:const_set, :COMPONENTS, Adhearsion::Components.component_manager.lazy_config_loader)
      
      Adhearsion::Components.component_manager.globalize_global_scope!
      Adhearsion::Components.component_manager.extend_object_with(Adhearsion::Events, :events)
      Adhearsion::Components.component_manager.load_components

      # add the old loader method to ExecutionEnvironment
      Adhearsion::DialPlan::ExecutionEnvironment.class_eval do
        alias_method :extend_with_dialplan_methods_old!, :extend_with_dialplan_methods!

        def extend_with_dialplan_methods!
          extend_with_dialplan_methods_old!
          Adhearsion::Components.component_manager.extend_object_with(self, :dialplan) if Adhearsion::Components.component_manager
        end
      end

    else
      logger.warn "No components directory found. Not initializing any components."
    end
  end
end