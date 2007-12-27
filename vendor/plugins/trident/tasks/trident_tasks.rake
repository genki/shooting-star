desc 'Start trident environment.'
task :trident do
  tail = Process.fork{exec 'tail -f log/development.log'}
  autotest = Process.fork{exec 'autotest'}
  sh './script/console'
  Process.kill(:HUP, tail, autotest)
end
