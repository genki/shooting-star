namespace :meteor_strike do
  desc 'Update meteor_strike plugin'
  task :update do
    sh 'shooting_star init'
    sh './script/generate meteor -f'
  end
end
