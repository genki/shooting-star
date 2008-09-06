Gem::Specification.new do |s|
  s.name = %q{shooting_star}
  s.version = "3.2.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Genki Takiuchi"]
  s.date = %q{2008-09-07}
  s.default_executable = %q{shooting_star}
  s.description = %q{Our goal is development of practical comet server which will be achieving over 100,000 simultaneous connections per host. On this purpose, we abandon portability and use system calls depending on particular OS such as epoll and kqueue.  == FEATURES/PROBLEMS:  * Comet server * Comet client implementation (Rails plugin)  == SYNOPSYS:}
  s.email = %q{genki@s21g.com}
  s.executables = ["shooting_star"]
  s.extensions = ["ext/extconf.rb"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/shooting_star", "lib/shooting_star.rb", "lib/shooting_star/version.rb", "lib/shooting_star/server.rb", "lib/shooting_star/shooter.rb", "lib/shooting_star/channel.rb", "lib/shooting_star/config.rb", "lib/form_encoder.rb", "ext/asteroid.c", "ext/extconf.rb", "ext/asteroid.h", "test/test_helper.rb", "test/lib/shooting_star_test.rb", "test/lib/test_c10k_problem.c", "test/ext/asteroid_test.rb", "vendor", "vendor/plugins", "vendor/plugins/meteor_strike", "vendor/plugins/meteor_strike/README", "vendor/plugins/meteor_strike/Rakefile", "vendor/plugins/meteor_strike/init.rb", "vendor/plugins/meteor_strike/lib", "vendor/plugins/meteor_strike/lib/meteor_strike.rb", "vendor/plugins/meteor_strike/lib/meteor_strike", "vendor/plugins/meteor_strike/lib/meteor_strike/helper.rb", "vendor/plugins/meteor_strike/lib/meteor_strike/controller.rb", "vendor/plugins/meteor_strike/views", "vendor/plugins/meteor_strike/views/xhr.rhtml", "vendor/plugins/meteor_strike/views/flash.rhtml", "vendor/plugins/meteor_strike/tasks", "vendor/plugins/meteor_strike/tasks/meteor_strike.rake", "vendor/plugins/meteor_strike/test", "vendor/plugins/meteor_strike/test/meteor_strike_test.rb", "vendor/plugins/meteor_strike/generators", "vendor/plugins/meteor_strike/generators/meteor", "vendor/plugins/meteor_strike/generators/meteor/meteor_generator.rb", "vendor/plugins/meteor_strike/generators/meteor/templates", "vendor/plugins/meteor_strike/generators/meteor/templates/controller.rb", "vendor/plugins/meteor_strike/generators/meteor/templates/model.rb", "vendor/plugins/meteor_strike/generators/meteor/templates/helper.rb", "vendor/plugins/meteor_strike/generators/meteor/templates/view.rhtml", "vendor/plugins/meteor_strike/generators/meteor/templates/migration.rb", "vendor/plugins/meteor_strike/generators/meteor/templates/unit_test.rb", "vendor/plugins/meteor_strike/generators/meteor/templates/functional_test.rb", "vendor/plugins/meteor_strike/generators/meteor/templates/meteor_strike.swf", "vendor/plugins/meteor_strike/generators/chat", "vendor/plugins/meteor_strike/generators/chat/chat_generator.rb", "vendor/plugins/meteor_strike/generators/chat/templates", "vendor/plugins/meteor_strike/generators/chat/templates/controller.rb", "vendor/plugins/meteor_strike/generators/chat/templates/model.rb", "vendor/plugins/meteor_strike/generators/chat/templates/helper.rb", "vendor/plugins/meteor_strike/generators/chat/templates/layout.rhtml", "vendor/plugins/meteor_strike/generators/chat/templates/index.rhtml", "vendor/plugins/meteor_strike/generators/chat/templates/show.rhtml", "vendor/plugins/meteor_strike/generators/chat/templates/migration.rb", "vendor/plugins/meteor_strike/generators/chat/templates/unit_test.rb", "vendor/plugins/meteor_strike/generators/chat/templates/functional_test.rb"]
  s.has_rdoc = true
  s.homepage = %q{    by Genki Takiuchi <genki@s21g.com>}
  s.rdoc_options = ["-S", "--template", "kilmer", "--main", "README.txt", "--exclude", "ext/asteroid", "README.txt"]
  s.require_paths = ["lib", "ext"]
  s.rubyforge_project = %q{shooting-star}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Our goal is development of practical comet server which will be achieving over 100,000 simultaneous connections per host. On this purpose, we abandon portability and use system calls depending on particular OS such as epoll and kqueue.}
  s.test_files = ["test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 1.7.0"])
    else
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 1.7.0"])
    end
  else
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 1.7.0"])
  end
end
