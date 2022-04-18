# frozen_string_literal: true

require 'telegram/bot'

class Sender
  OLD_TEXT = "Please subscribe to the ton NFT drop. Thank you :)\n\n"\
             "Подпишись пожалуйста на розыгрыш тон NFT. Спасибо :)\n\n"\
             "<a href='https://t.me/TonDiamondsDropBot?start=593856889'>Можно перейти по моей реферальной ссылке</a>"

  OLD_TEXT_1 = "🎁 Prize draw from TON Bulls and TON Memes\n"\
               "The top 25 participants in terms of the number of points will receive - 1 NFT.\n"\
               "Participants with more than 2500 points will receive meme tokens from TON Memes.\n"\
               "<a href='https://t.me/tongemsbot?start=0897749204'>You can follow my referral link</a>\n\n"\
               "🎁 Розыгрыш от TON Bulls и TON Memes\n"\
               "Топ-25 участников по кол-ву баллов получат – 1 NFT.\n"\
               "Участники набравшие более 2500 баллов получат мем-токены от TON Memes.\n"\
               "<a href='https://t.me/tongemsbot?start=0897749204'>Можно перейти по моей реферальной ссылке</a>"

  OLD_TEXT_2 = "About 4 hours bot will be unavailable.\n"\
               'Около 4-х часов бот будет недоступен.'

  OLD_TEXT_3 = "Giving away 999 NFTs from TON Chinchillas NFT!\n"\
               "The first 333 participants who scored 100 points will receive 1 NFT each.\n"\
               "The remaining 666 NFT will be given randomly.\n"\
               "<a href='https://t.me/tonchinchibot?start=r0897749204'>You can follow my referral link</a>\n\n"\
               "Раздача 999 NFT от TON Chinchillas NFT!\n"\
               "Первые 333 участника, набравшие 100 баллов, получат по 1 NFT.\n"\
               "Остальные 666 NFT будут выданы случайным образом.\n"\
               "<a href='https://t.me/tonchinchibot?start=r0897749204'>Можно перейти по моей реферальной ссылке</a>"

  OLD_TEXT_4 = "<b><u><a href='https://t.me/nftngio/4'>Что-то новенькое от команды toncoinpool.io… 🚀</a></u></b>\n\n"\
               "<b>NFT NG</b> — Уникальные цифровые активы от ваших любимых разработчиков <u>toncoinpool.io</u>.\n"\
               "<u>@nftngio</u> - следите за новостями! ❤️‍🔥\n\n\n"\
               "<b><u><a href='https://t.me/nftngio/4'>Something new is coming from the toncoinpool.io team... 🚀</a>"\
               "</u></b>\n\n"\
               "<b>NFT NG</b> - unique digital assets project from your favourite <u>toncoinpool.io</u> devs.\n"\
               "<u>@nftngio</u> - stay in touch! ❤️‍🔥\n"

  class << self
    attr_accessor :bot

    def send_message(user_id, chat_id, text, **args)
      # opts = { parse_mode: :html, chat_id: chat_id, text: text }.merge!(args)
      opts = { parse_mode: :html, chat_id: chat_id, text: text, disable_web_page_preview: true }.merge!(args)
      bot.api.send_message(opts)
    rescue StandardError => e
      log("Sending message is blocking by the user #{User.find_by(tg_id: user_id).debug_user_info}\n"\
          "Error: -----> #{e.message}\n"\
          '<-----------------------')
    end

    def delete_message(message)
      bot.api.delete_message(chat_id: message.chat.id, message_id: message.message_id)
    rescue StandardError => e
      log("Deleting message error for user #{User.find_by(tg_id: message.from.id).debug_user_info}\n"\
          "Error: -----> #{e.message}\n"\
          '<-----------------------')
    end

    def send_direct_message_to_all_users(text)
      Telegram::Bot::Client.run(Config.token) do |bot|
        Sender.bot = bot

        User.find_each do |user|
          Thread.new do
            log "Send for #{user.debug_user_info}"
            send_message(user.tg_id, user.chat_id, text)
          end
        end
      end
    end

    def send_direct_message_to_specific_users(users, text)
      Telegram::Bot::Client.run(Config.token) do |bot|
        Sender.bot = bot

        users.find_each do |user|
          Thread.new do
            log "Send for #{user.debug_user_info}"
            send_message(user.tg_id, user.chat_id, text)
          end
        end
      end
    end

    def send_direct_message_to_user(user_id, text)
      Telegram::Bot::Client.run(Config.token) do |bot|
        Sender.bot = bot
        Thread.new do
          user = User.find(user_id)
          log "Send for #{user.debug_user_info}"
          send_message(user.tg_id, user.chat_id, text)
        end
      end
    end
  end

  attr_accessor :message, :user

  def initialize(message, user)
    @message = message
    @user = user
  end

  def default_response(text = user.t('main_menu'), with_replacing: true)
    kb = [
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: user.t('wallet_data'))],
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: user.t('pool_data'))],
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: user.t('profit_calculating'))],
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: user.t('settings'))]
    ]
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb, resize_keyboard: true)
    send_message(text, with_replacing: with_replacing, reply_markup: markup)
  end

  def settings_response(text = "#{user.t('settings')}:", with_replacing: true)
    kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: user.t('notify_on')),
           Telegram::Bot::Types::InlineKeyboardButton.new(text: user.t('notify_off'))],
          [Telegram::Bot::Types::InlineKeyboardButton.new(text: user.t('change_time_zone')),
           Telegram::Bot::Types::InlineKeyboardButton.new(text: user.t('switch_language'))],
          Telegram::Bot::Types::InlineKeyboardButton.new(text: user.t('set_wallet')),
          Telegram::Bot::Types::InlineKeyboardButton.new(text: user.t('back_to_main_menu'))]
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb, resize_keyboard: true)
    send_message(text, with_replacing: with_replacing, reply_markup: markup)
  end

  def with_keyboard_close(text = 'Keyboard closed', with_replacing: true)
    kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    send_message(text, with_replacing: with_replacing, reply_markup: kb)
  end

  def send_message(text, with_replacing: false, **args)
    with_replacing && delete_message
    self.class.send_message(message.from.id, message.chat.id, text, **args)
  end

  def delete_message
    self.class.delete_message(message)
  end
end
