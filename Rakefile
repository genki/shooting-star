require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'

namespace :gem do
  require 'hoe'

  $: << './lib'
  $: << './ext'
  require 'shooting_star'

  Hoe.new('shooting_star', ShootingStar::VERSION) do |hoe|
    hoe.author = 'Genki Takiuchi'
    hoe.email = 'takiuchi@drecom.co.jp'
    hoe.description = 'Comet server.'
    hoe.rubyforge_name = 'shooting-star'
    hoe.summary = hoe.paragraphs_of('README.txt', 2)[0]
    hoe.description = hoe.paragraphs_of('README.txt', 2..5).join("\n\n")
    hoe.url = hoe.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
    hoe.changes = hoe.paragraphs_of('History.txt', 0..1).join("\n\n")
    hoe.spec_extras = {
      :extensions => 'ext/extconf.rb',
      :rdoc_options => ['-S',
        '--template', 'kilmer',
        '--main', 'README.txt',
        '--exclude', 'ext/asteroid',
        'README.txt']
    }
  end
end

desc 'default gem task.'
task :gem => 'gem:default'

desc 'update generator template files.'
task 'update_generator_template_files' do
  templates = 'vendor/plugins/meteor_strike/generators/meteor/templates'
  cp 'app/controllers/meteor_controller.rb',
    templates + '/controller.rb'
  cp 'app/models/meteor.rb',
    templates + '/model.rb'
  cp 'app/helpers/meteor_helper.rb',
    templates + '/helper.rb'
  cp 'app/views/meteor/strike.rhtml',
    templates + '/view.rhtml'
  cp 'test/unit/meteor_test.rb',
    templates + '/unit_test.rb'
  cp 'test/functional/meteor_controller_test.rb',
    templates + '/functional_test.rb'
end

desc 'test all tests'
task 'test:all' => [:test, 'test:plugins', 'test:exts', 'test:libs']
