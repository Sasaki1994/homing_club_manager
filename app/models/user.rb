class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :registerable, 
         :rememberable, :omniauthable,
         authentication_keys: [:line_id]
  validates_uniqueness_of :line_id

  def email_required?
    false
  end

  def will_save_change_to_email?
    false
  end

  def get_aleart_time()
  end

  def get_go_home_message(key_message)
    @adress = key_message
    home_route_data = get_home_route 
    if home_route_data[:home_time] == nil
      message = "時刻検索に失敗しました\n以下のURLを開発者に報告してください。\n" + home_route_data[:url]
    elsif is_last_train
      message  = "終電に乗るには" + home_route_data[:leave_time] + "までにはここを出ましょう。"
      message += "\n10分前にアラートします。"
      message += "\n電車遅延しているかもしれません。" if home_route_data[:accident]
      message += "\n" + home_route_data[:url]
    else
      message = home_route_data[:home_time] + "に家に着きます。"
      message = message + "\n電車遅延しているかもしれません。" if home_route_data[:accident]
      message = message + "\n" + home_route_data[:url]
    end

    return message
  end

  def get_home_route
       
        if is_last_train then
          type = 2
        else
          type = 1
        end
        time = Time.current
        from_station = @adress.delete("、").delete(" ").delete("　")
        to_station = home_station
        year =  time.year.to_s
        month =  format('%02d', time.month.to_s)
        day =  format('%02d', time.day.to_s)
        hour =  format('%02d', time.hour.to_s)
        min1 = time.min.div(10).to_s
        min2 = (time.min % 10).to_s

        agent = Mechanize.new
        #https://transit.yahoo.co.jp/search/result?&from=大和&to=戸塚&ym=201912&d=09&hh=17&m2=1&m1=5
        url = "https://transit.yahoo.co.jp/search/result?from=#{from_station}&to=#{to_station}&ym=#{year+month}&d=#{day}&hh=#{hour}&m2=#{min2}&m1=#{min1}&type=#{type}"
        page = agent.get(url)
        arrive_time_ele = page.search('div#route01 li.time span.mark').inner_text
        leave_time_ele = page.search('div#route01 li.time span').inner_text
        leave_time_ele = leave_time_ele.match(/(.+)発/)[1] ##################################################

        if arrive_time_ele == ""
            return {url: url, home_time: nil, accident: nil}
        end

        arrive_time =  Time.zone.parse(arrive_time_ele.chop)
        leave_time =  Time.zone.parse(leave_time_ele)
        leave_time = leave_time + 3600 * 24 if leave_time < Time.current
        home_time = arrive_time + 60 * time_for_station
        alert_time = leave_time - 60 * 10
        update(alert_at: alert_time) if type == 2
        leave_time = leave_time.strftime('%H:%M')
        alert_time = alert_time.strftime('%H:%M')
        home_time = home_time.strftime('%H:%M')


        if page.at('div#route01 li.time span.icnAlert')
            accident = true
        else
            accident = false
        end

        return {url: url, home_time: home_time, accident: accident, leave_time: leave_time, alert_time: alert_time}
  end

  
end
