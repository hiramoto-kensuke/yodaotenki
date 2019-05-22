Rails.application.routes.draw do
  post '/line/bot', to: 'linebot#bot'
end
