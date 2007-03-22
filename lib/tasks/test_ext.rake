require 'rake'
require 'rake/testtask'

namespace :test do
  desc 'Test extensions.'
  Rake::TestTask.new(:exts) do |t|
    t.pattern = File.join(RAILS_ROOT, 'test/ext/**/*_test.rb')
    t.verbose = true
  end
end
