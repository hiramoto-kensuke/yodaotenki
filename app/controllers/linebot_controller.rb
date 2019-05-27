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
          xpath = 'weatherforecast/pref/area[4]/'

          min_per = 20 #最終的には30に変更

          case input
            # 「明日」or「あした」というワードが含まれる場合
          when /.*(明日|あした).*/
            per06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text

            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push = "明日は雨が降りそうじゃな。\nいまのところの降水確率は以下の通りじゃ。\n\n  6 〜12時  #{per06to12}%\n 12〜18時  #{per12to18}%\n 18〜24時  #{per18to24}%\n\nパダワンよ、未来は絶えず揺れ動く。\n明日には降水確率も変わってるかもしれんな。"
            else
              push = "明日の天気か？\n雨は振らないようじゃの。\nしかし、未来は絶えず揺れ動く。\n明日また尋ねるがよい。"
            end

          when /.*(明後日|あさって).*/
            per06to12 = doc.elements[xpath + 'info[3]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[3]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[3]/rainfallchance/period[4]'].text

            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push = "明後日？\n雨は生命の営みの一部なのじゃ。\n雨へと変わる空を喜んで送り出せ。\n\n  6 〜12時  #{per06to12}%\n 12〜18時  #{per12to18}%\n 18〜24時  #{per18to24}%\n\n嘆いてはならぬ。寂しがってもならぬ。執着は嫉妬を生み、欲望の影が忍び寄るぞ。"
            else
              push = "明後日の天気、かの？\nいまのところは、晴れるようじゃ。\nしかし、未来を見るときには気をつけよ、パダワン。\n喪失への恐れは、ダークサイドへの入り口なのじゃ。"
            end


          when /.*(未来).*/
            push = "ふむ、ダークサイドが全てを曇らせておる。未来を読むのは難しい。\nわしに見えるのは明後日までの未来のようじゃ。"

          when /.*(名言|めいげん).*/
            word =
                ["恐れはダークサイドに通じる。\n恐れは怒りに通じ、怒りは憎しみに通じる。\n憎しみは苦しみとなるのじゃ。",
                "一度ダークサイドに堕ちれば、二度と逃れることはできんのじゃ。",
                "ジェダイはフォースを身を守るために使うのじゃ、攻撃にではない。",
                "大きさは問題ではない。\nわしを見ろ、体のサイズで強さを判断するのか？",
                "やってみるではダメじゃ。\nやるか、さもなければやらないかじゃ。トライなんてものはないんじゃ。",
                "忍耐強くならないとダメじゃ、若きパダワンよ。",
                "生徒が聞きたくないからってヨーダが教えるのを止めると思っているか？\nヨーダは先生なんじゃ。\nヨーダは酔っ払いが飲むように、殺し屋が殺すように、教えるんじゃ。",
                "フォースと共にあらんことを。",
                "失いたくない全てのものを解放するように自分を鍛えるんじゃ",
                "ダークサイドを覗くときは、向こうが覗き返してこないかどうか気をつけるんじゃ"].sample
            push = "#{word}"
          else
            per06to12 = doc.elements[xpath + 'info/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info/rainfallchance/period[4]'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              word =
                  ["フォースを使え、感じるのじゃ。",
                  "フォースはお前とわしの間にもある。\n雨にも、木にも。至るところにある！",
                  "雨は生きることの一部じゃ。"].sample
              push = "今日は雨が降りそうじゃから、傘があったほうが安心じゃな。\n  6 〜12時  #{per06to12}%\n 12〜18時  #{per12to18}%\n 18〜24時  #{per18to24}%\n\n#{word}"
            else
              word =
                  ["雨が降ったらすまんの。",
                  "修行はもう必要ない。学ぶべきものはすでに身についておる。",
                  "フォースとともにあらんことを。"].sample
              push = "今日は雨は振らなそうじゃの。\n#{word}"
            end


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