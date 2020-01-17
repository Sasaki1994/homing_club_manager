class LineBotController < ApplicationController
    require 'line/bot'
    require 'json'
    protect_from_forgery :except => [:callback, :test]

    @@regis_richmenu_id = "richmenu-f5970ae73b217ebac57c44f1f73539e2"
    @@loc_richmenu_id =  "richmenu-88e51938cae62d1eb6f2d6861b457866"
    @@norm_richmenu_id = "richmenu-5e99b91c78df5c5307c835b5f18afbaa"
    @@alert_richmenu_id = "richmenu-80b4cc0ef167ef96ca3fef8dd76fa014"
    URL = "https://homing-club-manager.herokuapp.com/"


    #メッセージ受信時の処理とレスポンス
    def callback
        event = get_event()
        if event == nil
          return head :ok
        end


        line_id = event['source']['userId']
        user = User.find_by(line_id: line_id)

        if user.present? && user.home_station

          #会社からか現在地からかの分岐、メッセージの構築
          if event['type'] == "postback" then
            recog = event['postback']["data"]
            recog_message(user, recog)
          elsif event.message['type'] == "location" then
            address = event.message['address']
            if user.is_last_train
                self.change_rich_menu(user.line_id, @@alert_richmenu_id)
                message = user.get_go_home_message(key_message=address)
                user.update(is_last_train: false)
            else
                self.change_rich_menu(user.line_id, @@norm_richmenu_id)
                message = user.get_go_home_message(key_message=address)
            end
            reply(event['replyToken'], message)
          end

        else
          reply(event['replyToken'], "登録してください。 URL: #{URL}")
        end

        head :ok
    end


    def test
      event = get_event()
        if event == nil
          return head :ok
        end

        line_id = event['source']['userId']
        user = User.find_by(line_id: line_id)


        #会社からか現在地からかの分岐、メッセージの構築
        if event.message['type'] == "text" then
          text = event.message['text']
          message = text + "でした"
        elsif event.message['type'] == "location" then
          
        end
      submit(user.line_id, message)

      return head :ok
  
    end

    def change_rich_menu(line_id, richmenu_id)
        client.link_user_rich_menu(line_id, richmenu_id)
    end

    def self.submit_alert
        users = User.where("alert_at < ?", Time.current)
        if users.length != 0
            user_ids = []
            users.each do |user|
                user.update(alert_at: nil, is_last_train: false)
                user_ids << user.line_id
            end
            client.multicast(user_ids, "終電間近です！")
        end
    end

    def self.set_rich_menu(name, filename)
        
        rich_menu = self.get_rich_menu(name)
        res = JSON.parse(client.create_rich_menu(rich_menu).body)
        
        begin
            # エラーを起こす可能性のあるコード
            File.open(Rails.public_path + filename, "r") do |file|
            client.create_rich_menu_image(res["richMenuId"], file)
            end
            # 例外オブジェクトを変数 error に代入
        rescue => error
            # 変数の値を表示
            client.delete_rich_menu(res["richMenuId"])
            puts error
        end
        client.set_default_rich_menu(res["richMenuId"])
    end

    def self.delete_rich_menu
        
        rich_menus = JSON.parse(client.get_rich_menus.body)["richmenus"]
        i = 1
        p rich_menus
        rich_menus.each do |rich_menu|

            puts "[#{i.to_s}] #{rich_menu["name"]}"
            i+= 1
        end
        input = gets.to_i
        client.delete_rich_menu(rich_menus[input-1]["richMenuId"])
        
        rich_menus = JSON.parse(client.get_rich_menus.body)["richmenus"]
        i = 1
        rich_menus.each do |rich_menu|

            puts "[#{i.to_s}] #{rich_menu["name"]}"
            i+= 1
        end
    end

    def self.set_default_rich_menu
        client.set_default_rich_menu("richmenu-f5970ae73b217ebac57c44f1f73539e2")
    end


    private
    #テキストメッセージの意図判断
    def recog_message(user, recog)
      if recog == 'now'
        user.update(is_last_train: false)
        self.change_rich_menu(user.line_id, @@loc_richmenu_id)
      elsif recog == 'last'
        user.update(is_last_train: true)
        self.change_rich_menu(user.line_id, @@loc_richmenu_id)
      elsif recog == 'change'
        user.update(is_last_train: true)
        self.change_rich_menu(user.line_id, @@loc_richmenu_id)
      elsif recog == 'reset'
        user.update(is_last_train: false, alert_at: nil)
        self.change_rich_menu(user.line_id, @@norm_richmenu_id)
      elsif recog == 'cancel'
        user.update(is_last_train: false)
        self.change_rich_menu(user.line_id, @@norm_richmenu_id)
      else
        puts  "認識できませんでした"
      end
    end


    #メッセージ受信時の情報取得
    def get_event
        body = request.body.read
        signature = request.env['HTTP_X_LINE_SIGNATURE']
        # p client.validate_signature(body, signature)
        unless client.validate_signature(body, signature)
          head :BadRequest
        end
        events = client.parse_events_from(body)
    
        events.each do |event|
        
          case event
          when Line::Bot::Event::Message
            case event.type
            when Line::Bot::Event::MessageType::Text then
              return event
            when Line::Bot::Event::MessageType::Location then
              return event
            end         
          when Line::Bot::Event::Postback then
            return event
          end
        end

        return nil

    end


    #メッセージ送信処理
    def submit(line_id, message_text)
      message = {
            type: 'text',
            text: message_text,
          }
      client.push_message(line_id, message)
    end

    def reply(reply_token, message_text)
      message = {
        type: 'text',
        text: message_text
      }
      client.reply_message(reply_token, message)
    end

    def self.get_rich_menu(name)

        

        regist_actions =[{
            "type": "uri",
            "uri": URL
        }]

        normal_actions=[
        {
            "type": "postback",
            "data": "now",
        },

        {
            "type": "postback",
            "data": "last"
        },

        {
            "type": "uri",
            "uri": URL
        }
        ]

        alert_actions=[
            {
                "type": "postback",
                "data": "now",
            },
    
            {
                "type": "postback",
                "data": "last"
            },
    
            {
                "type": "postback",
                "data": "reset"
            }
        ]

        location_actions=[
            {
                "type": "uri",
                "uri": "line://nv/location",
            },
    
            {
                "type": "postback",
                "data": "cancel"
            },
        ]
    

        rich_menu = {
            "size": {
              "width": 2500,
              "height": 843
            },
            "selected": false,
            "name": name,
            "chatBarText":"モード選択",
            "areas": [
              {
                "bounds": {
                  "x": 0,
                  "y": 0,
                  "width": 2500,
                  "height": 843
                },
                "action": regist_actions[0]
              },
            #   {
            #     "bounds": {
            #       "x": 1250,
            #       "y": 0,
            #       "width": 1250,
            #       "height": 843
            #     },
            #     "action": location_actions[1]
            #   },
            #   {
            #     "bounds": {
            #       "x": 1666,
            #       "y": 0,
            #       "width": 834,
            #       "height": 843
            #     },
            #     "action": alert_actions[2]
            #   }
            ]
          }
        return rich_menu
    end

    

    #linebotクライアント情報の取得
    def client
        @client ||= Line::Bot::Client.new { |config|
          config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
          config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
        }
    end
end
