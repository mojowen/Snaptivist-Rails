task :deploy, :remote, :branch do |t,args|

  branch_to_push = args[:branch] || 'master'

  remote = args[:remote] || 'heroku'


  begin
    blue "Pushing to origin"
    system "git push origin #{branch_to_push}"
    blue 'Checking out Compiled'
    system 'git stash'
    system "git checkout -B compiled"
    system "git merge -s recursive -Xtheirs #{branch_to_push}"

    blue 'Precompiling Assets'
    system 'bundle exec rake assets:clean'
    system 'bundle exec rake assets:precompile'

    blue 'Commiting to compiled'
    system 'git add public/assets/'
    system "git commit -am 'Precompiling assets'"

    system "git push -f #{remote} compiled:master"
  rescue Exception => e
    red "!!!! Something went wrong"
    red e.message
  ensure
    blue ">>>> Back to #{branch_to_push}"
    system "git checkout #{branch_to_push}"
    system 'git stash pop'
  end

end

def blue msg
  puts "\033[34m#{msg}\033[0m"
end

def red msg
  puts "\033[35m#{msg}\033[0m"
end


