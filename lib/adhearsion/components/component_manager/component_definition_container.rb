module Adhearsion
  module Components
    class ComponentManager

      class ComponentDefinitionContainer < Module

        def initialize(&block)
          # Hide our instance variables in the singleton class
          metadata = {}
          singleton_class.send(:instance_variable_set, :@metadata, metadata)

          metadata[:scopes] = ComponentManager::SCOPE_NAMES.inject({}) do |scopes, name|
            scopes[name] = []
            scopes
          end

          super

          singleton_class.send(:define_method, :initialize) do
            raise "This object has already been instantiated. Are you sure you didn't mean initialization()?"
          end
        end

        def methods_for(*scopes, &block)
          raise ArgumentError if scopes.empty?

          ComponentManager.scopes_valid? scopes
            
          metadata = singleton_class.send(:instance_variable_get, :@metadata)
          scopes.each { |scope| metadata[:scopes][scope] << block }
        end

        def initialization(&block)
          # Raise an exception if the initialization block has already been set
          metadata = singleton_class.send(:instance_variable_get, :@metadata)
          if metadata[:initialization_block]
            raise "You should only have one initialization() block!"
          else
            metadata[:initialization_block] = block
          end
        end

        class << self
          def load_code(code)
            new.tap do |instance|
              case code
              when Proc
                instance.instance_exec &code
              else
                instance.module_eval code
              end
            end
          end

          def load_file(filename)
            new.tap do |instance|
              instance.module_eval File.read(filename), filename
            end
          end

          def require(filename)
            filename = filename + ".rb" if !(filename =~ /\.rb$/)
            begin
              # Try loading the exact filename first
              load_file(filename)
            rescue LoadError, Errno::ENOENT
            end

            # Next try Rubygems
            filepath = get_gem_path_for(filename)
            return load_file(filepath) if !filepath.nil?

            # Finally try the system search path
            filepath = get_system_path_for(filename)
            return load_file(filepath) if !filepath.nil?

            # Raise a LoadError exception if the file is still not found
            raise LoadError, "File not found: #{filename}"
          end
        end

        protected

        class << self
          def self.method_added(method_name)
            @methods ||= []
            @methods << method_name
          end

          def get_gem_path_for(filename)
            # Look for component files provided by rubygems
            spec = Gem.searcher.find(filename)
            return nil if spec.nil?
            File.join(spec.full_gem_path, spec.require_path, filename)
          rescue NameError
            # In case Rubygems are not available
            nil
          end

          def get_system_path_for(filename)
            $:.each do |path|
              filepath = File.join(path, filename)
              return filepath if File.exists?(filepath)
            end

            # Not found? Return nil
            return nil
          end
        end

      end
    end
  end
end