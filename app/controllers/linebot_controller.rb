class LinebotController < ApplicationController
  require 'line/bot'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  protect_from_forgery :except => [:callback]

  def callback
    #LINEプラットフォームから送信されたか検証
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do
        'Bad Request'
      end
    end
    events = client.parse_events_from(body)
    events.each { |event|
      case event
        # メッセージが送信された場合の対応（機能①）
      when Line::Bot::Event::Message
        case event.type
          # ユーザーからテキスト形式のメッセージが送られて来た場合
        when Line::Bot::Event::MessageType::Text
          # event.message['text']：ユーザーから送られたメッセージ
          input = event.message['text']

          url = "https://www.drk7.jp/weather/xml/13.xml"
          xml = open(url).read.toutf8
          doc = REXML::Document.new(xml)
          xpath = 'weatherforecast/pref/area[4]/info'

          min_per = 20 #最終的には30に変更

          case input
            # 「明日」or「あした」というワードが含まれる場合
          when /.*(明日|あした).*/
            per06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text

            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push = "明日は雨が降りそうじゃな。\nいまのところの降水確率は以下の通りじゃ。\n 6〜12時 #{per06to12}%\n 12〜18時 #{per12to18}%\n 18〜24時 #{per18to24}%\nパダワンよ、未来は絶えず揺れ動く。\n明日には降水確率も変わってるかもしれんな。。。"
            else
              push = "明日の天気か？\n雨は振らないようじゃの。\nしかし、未来は絶えず揺れ動く。\n明日また尋ねるがよい。"
            end

          when /.*(テスト|てすと).*/
            push = "テストてすと"

          end
        end
        message = {
            type: 'text',
            text: push
        }
        client.reply_message(event['replyToken'], message)
      end
    }
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new {|config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end