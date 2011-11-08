module Adhearsion
  module Components
    class ComponentManager

      class ComponentMethodDefinitionContainer < Module
        attr_reader :scopes
        
        def initialize(*scopes, &block)
          @scopes = []
          super(&block)
        end

        class << self
          def method_added(method_name)
            @methods ||= []
            @methods << method_name
          end
        end

      end

    end
  end
end