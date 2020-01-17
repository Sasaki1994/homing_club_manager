require File.expand_path(File.dirname(__FILE__) + "/environment")

# 実行環境を指定する
set :environment, Rails.env.to_sym
# 実行logの出力先
set :output, "#{Rails.root.to_s}/log/cron.log"

every 1.minute do # 1.minute 1.day 1.week 1.month 1.yearなどをサポート
  runner "LineBotController.submit_alert"
end
