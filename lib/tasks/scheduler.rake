desc "This task is called by the Heroku scheduler add-on"
task :test_scheduler => :environment do
  puts "scheduler test"
  puts "it works."
end

task :submit_alert => :environment do
  LineBotController.submit_alert
end

task :submit_alert2 => :environment do
    LineBotController.submit_alert
end

task :submit_alert3 => :environment do
    LineBotController.submit_alert
end

task :submit_alert4 => :environment do
    LineBotController.submit_alert
end

task :submit_alert5 => :environment do
    LineBotController.submit_alert
end

task :submit_alert6 => :environment do
    LineBotController.submit_alert
end

task :submit_alert7 => :environment do
    LineBotController.submit_alert
end

task :submit_alert8 => :environment do
    LineBotController.submit_alert
end

task :submit_alert9 => :environment do
    LineBotController.submit_alert
end
