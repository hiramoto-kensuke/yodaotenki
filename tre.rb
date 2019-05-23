class LinebotController < ApplicationController
require 'line/bot' # gem 'line-bot-api'
require 'open-uri'
require 'kconv'
require 'rexml/document'

# 外部からpostを送れるように
protect_from_forgery :except => [:callback]

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
      # メッセージが送信された場合の対応（機能①）
    when Line::Bot::Event::Message
      case event.type
        # ユーザーからテキスト形式のメッセージが送られて来た場合
      when Line::Bot::Event::MessageType::Text
        # event.message['text']：ユーザーから送られたメッセージ
        input = event.message['text']
        case input
          # 「明日」or「あした」というワードが含まれる場合
        when /.*(明日|あした).*/
          push = "明日じゃな"

        when /.*(テスト|てすと).*/
          push = "テストてすと"
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