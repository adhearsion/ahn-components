$:.unshift(File.join(File.dirname(__FILE__), "support"))

require 'flexmock'
require 'flexmock/rspec'


RSpec.configure do |config|
  config.mock_framework = :flexmock
  config.filter_run_excluding :ignore => true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

module Adhearsion
  class Plugin
    def self.init(name)
    end

    def self.config(name)
    end
  end
end

require 'ahn-components'
require 'adhearsion/component_manager/component_tester'


class Object
  alias :the_following_code :lambda
end

