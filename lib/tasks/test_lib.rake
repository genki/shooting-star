require 'rake'
require 'rake/testtask'

namespace :test do
  desc 'Test libs.'
  Rake::TestTask.new(:libs) do |t|
    t.pattern = File.join(RAILS_ROOT, 'test/lib/**/*_test.rb')
    t.verbose = true
  end
end
