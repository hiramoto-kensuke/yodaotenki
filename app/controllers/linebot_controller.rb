class LinebotController < ApplicationController
  require 'line/bot'
  require 'open-uri'
  #日本語文字コードへの変換ライブラリ
  require 'kconv'
  require 'rexml/document'

  #外部からpostを送れるようにする
  protect_from_forgery :exept => [:bot]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do
        'Bad Request'
      end
    end

    events = client.parse_events_from(body)
    events.each {|event|
      case event
      #メッセージが送信された場合の対応
      when Line::Bot::Event::Message
        case event.type
        #text形式のメッセージが送られてきた場合
        when Line::Bot::Event::MessageType::Text
          input = event.message['text']

          url = "https://www.drk7.jp/weather/xml/13.xml"
          #utf8に変換して取得(kconv)
          xml = open(url).read.toutf8
          doc = REXML::Document.new(xml)
          min_per = 0 #最終的には30にする?

          case input
          when /.*(明日|あした).*/
            push = "明日じゃな"

          when /.*(テスト|てすと).*/
            push = "テスト"
          end
    #
    #       #東京都 -> 東京地方の情報取得
    #       xpath = 'weatherforecast/pref/area[4]/info'
    #       weather = doc.elements[xpath + '/weather'].text
    #       per06to12 = doc.elements[xpath + '/rainfallchance/period[2]'].text
    #       per12to18 = doc.elements[xpath + '/rainfallchance/period[3]'].text
    #       per18to24 = doc.elements[xpath + '/rainfallchance/period[4]'].text
    #
    #
    #
    #
    # if per06to12 >= min_per || per12to18 >= min_per || per18to24 >= min_per
    #   push = "今日は傘を持つのじゃ。#{weather}じゃからの。"
    # end

          message = {
              type: 'text',
              text: push
          }
          client.reply_message(event['replyToken'], message)
    }
    head :ok
  end


  #MessagingAPIのリファレンスより

  private

  def client
    @client ||= Line::Bot::Client.new {|config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
