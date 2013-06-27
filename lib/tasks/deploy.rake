task :deploy, :remote, :branch do |t,args|

  branch_to_push = args[:branch] || 'master'

  remote = args[:remote] || 'heroku'
  base_domain = 'http://www.soundoffatcongress.org'

  # blue ">>>> Did you pull from #{branch_to_push}?"
  # pull = STDIN.gets.chomp.downcase

  # unless pull == 'true' || pull == 'yes' || pull == 'y'
  #   blue ">>>> Doing Git Pull - Make sure everything works then rake deploy again"
  #   system "git pull origin #{branch_to_push}"
  # else

    begin
      blue "Pushing to origin"
      system "git push origin #{branch_to_push}"
      blue 'Checking out Compiled'
      system 'git stash'
      system "git checkout -B compiled"
      system "git merge -s recursive -Xtheirs #{branch_to_push}"

      blue "Rewriting Base Domain to #{base_domain}"
      File.open('app/assets/javascripts/base_domain.js','w+'){ |f| f.write( "$oundoff_base_domain = '#{base_domain}'; " ) }

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
  # end

end

def blue msg
  puts "\033[34m#{msg}\033[0m"
end

def red msg
  puts "\033[35m#{msg}\033[0m"
end


