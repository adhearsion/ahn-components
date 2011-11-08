module Adhearsion
  module Components
    class ComponentManager

      class LazyConfigLoader
        def initialize(component_manager)
          @component_manager = component_manager
        end

        def method_missing(component_name)
          config = @component_manager.configuration_for_component_named(component_name.to_s)
          (class << self; self; end).send(:define_method, component_name) { config }
          config
        end
      end
    end
  end
end