module Adhearsion
  module Components
    class ComponentManager
      extend ActiveSupport::Autoload

      autoload :ComponentDefinitionContainer
      autoload :ComponentMethodDefinitionContainer
      autoload :LazyConfigLoader

      SCOPE_NAMES = [:dialplan, :events, :generators, :rpc, :global]

      attr_reader :scopes, :lazy_config_loader

      def initialize(path_to_container_directory)
        @path_to_container_directory = path_to_container_directory
        @scopes = SCOPE_NAMES.inject({}) do |scopes, name|
          scopes[name] = Module.new
          scopes
        end
        @lazy_config_loader = LazyConfigLoader.new(self)
      end

      ##
      # Includes the anonymous Module created for the :global scope in Object, making its methods globally accessible.
      def globalize_global_scope!
        Object.send :include, @scopes[:global]
      end

      def load_components
        components = Dir.glob(File.join(@path_to_container_directory + "/*")).select do |path|
          File.directory?(path)
        end

        components.map! { |path| File.basename path }
        components.each do |component|
          next if component.eql? "disabled"
          component_file = File.join(@path_to_container_directory, component, 'lib', component + ".rb")
          if File.exists? component_file
            load_file component_file
            next
          end

          # Try the old-style components/<component>/<component>.rb
          component_file = File.join(@path_to_container_directory, component, component + ".rb")
          if File.exists? component_file
            load_file component_file
          else
            logger.warn "Component directory does not contain a matching .rb file! Was expecting #{component_file.inspect}"
          end
        end

        # Load configured system- or gem-provided components
        AHN_CONFIG.components_to_load.each do |component|
          require component
        end
      end
      
      ##
      # Loads the configuration file for a given component name.
      #
      # @return [Hash] The loaded YAML for the given component name. An empty Hash if no YAML file exists.
      def configuration_for_component_named(component_name)
        # Look for configuration in #{AHN_ROOT}/config/components first
        if File.exists?("#{AHN_ROOT}/config/components/#{component_name}.yml")
          return YAML.load_file "#{AHN_ROOT}/config/components/#{component_name}.yml"
        end

        # Next try the local app component directory
        component_dir = File.join(@path_to_container_directory, component_name)
        config_file = File.join component_dir, "#{component_name}.yml"
        if File.exists?(config_file)
          YAML.load_file config_file
        else
          # Nothing found? Return an empty hash
          logger.warn "No configuration found for requested component #{component_name}"
          return {}
        end
      end

      def extend_object_with(object, *scopes)
        raise ArgumentError, "Must supply at least one scope!" if scopes.empty?

        self.class.scopes_valid? scopes

        scopes.each do |scope|
          methods = @scopes[scope]
          if object.kind_of?(Module)
            object.send :include, methods
          else
            object.extend methods
          end
        end
        object
      end

      def load_code(code)
        load_container ComponentDefinitionContainer.load_code(code)
      end

      def load_file(filename)
        load_container ComponentDefinitionContainer.load_file(filename)
      end

      def require(filename)
        load_container ComponentDefinitionContainer.require(filename)
      end

      class << self
        def scopes_valid?(*scopes)
          (scopes.flatten - SCOPE_NAMES).any? and raise ArgumentError, "Unrecognized scopes #{scopes.to_sentence}"
          true
        end
      end

      protected

      def load_container(container)
        container.constants.each do |constant_name|
          constant_value = container.const_get(constant_name)
          Object.const_set(constant_name, constant_value)
        end
        
        metadata = container.singleton_class.instance_variable_get(:@metadata)

        metadata[:initialization_block].call if metadata[:initialization_block]

        self.class.scopes_valid? metadata[:scopes].keys

        metadata[:scopes].each_pair do |scope, method_definition_blocks|
          method_definition_blocks.each do |method_definition_block|
            @scopes[scope].module_eval(&method_definition_block)
          end
        end
        container
      rescue StandardError => e
        # Non-fatal errors
        Events.trigger(['exception'], e) if defined? Events
      rescue Exception => e
        # Fatal errors.  Log them and keep passing them upward
        Events.trigger(['exception'], e) if defined? Events
        raise e
      end
    end
  end
end