
module Adhearsion
  module Components
    extend ActiveSupport::Autoload

    autoload :ComponentManager    

    class << self
      attr_accessor :component_manager
    end

    ConfigurationError = Class.new Exception

  end
end
