# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ahn-components/version"

Gem::Specification.new do |s|
  s.name        = "ahn-components"
  s.version     = Ahn::Components::VERSION
  s.authors     = ["juandebravo"]
  s.email       = ["juandebravo@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{This gem is an Adhearsion plugin that inherits the deprecated way to load components using the components folder}
  s.description = %q{With ahn-components you can ensure your Adhearsion application will load the components subfolder as it used to do in Adhearsion 1.x}

  s.rubyforge_project = "ahn-components"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "activesupport", [">= 3.0.10"]
  s.add_runtime_dependency "i18n", ">= 0.5.0"

  s.add_development_dependency "rspec", ">= 2.7.0"
  s.add_development_dependency "flexmock"
  s.add_development_dependency "rake", ">= 0.9.2"
end
