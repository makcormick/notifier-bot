# frozen_string_literal: true

=begin
BotFather command for mobile
wallet_data - Wallet data
set_wallet - Set wallet
pool_data - Pool data
profit_calculating - Profit calculating
notify_on - Notify On
notify_off - Notify Off
switch_language - Switch language
change_tz - Change time zone

RAILS_ENV=production rake start  // prod start
RAILS_ENV=production rc          // prod console
=end

require 'telegram/bot'

WatchDog.start = Time.now

class BotRuner
  def self.go!
    WatchDog.reload_when_error(self)
  end

  def self.go
    Telegram::Bot::Client.run(Config.token) do |bot|
      log 'Notifier is ready'

      Sender.bot = bot
      ReplyPool.bot = bot

      Looper.new(:transaction_data).start(Transaction::SCAN_TIMEOUT) do
        puts
        Transaction.deep_scan
      end

      Looper.new(:pool_fetcher).start(Api::PoolInfo::REQUEST_POOL_TIMEOUT, delay: 0.33) do
        puts
        Api::PoolInfo.fetch
        Api::Price::Gecko.price
      end

      Looper.new(:notifier).start(Transaction::SCAN_TIMEOUT, delay: 0.66) do
        puts
        log("Check new solutions. Memory 1-point #{GetProcessMem.new.mb}")
        next unless (solutions = Transaction.check_last_solutions)

        center_log 'Start users notify'
        log "Ton price #{Api::Price::Gecko.current_price}"
        log("Memory 2-point #{GetProcessMem.new.mb}")
        real_24h_profit_data = Transaction.real_24h_profit

        solutions.each do |solution|
          text = NotifyApi.last_giver_info(solution, time_zone: 3, real_24h_profit_data: real_24h_profit_data)
          puts('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> New Solution')
          log text
          puts('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<')
        end

        log("Memory 3-point #{GetProcessMem.new.mb}")
        User.notified.find_in_batches(batch_size: 10) do |users|
          log("Memory 4-point start #{GetProcessMem.new.mb}")
          threads = []
          users.each do |user|
            threads << Thread.new do
              solutions.each do |solution|
                ms_time = Benchmark.realtime do
                  text = NotifyApi.last_giver_info(solution, user: user, real_24h_profit_data: real_24h_profit_data)
                  Sender.send_message(user.tg_id, user.chat_id, text)
                end

                log "User notified #{user.tg_id} with #{ms_time} seconds"
              end
            end
          end
          threads.each(&:join)
          log("Memory 4-point end #{GetProcessMem.new.mb}")
          log("Sended for #{users.count} users")
          sleep(0.3)
        end

        log("Memory end #{GetProcessMem.new.mb}")
        center_log "End of all users (#{User.notified.count}) notify"
      end

      bot.listen do |message|
        user = User.find_or_create_by(tg_id: message.from.id) do |new_user|
          new_user.tg_id = message.from.id
          new_user.chat_id = message.chat.id
          new_user.first_name = message.from.first_name
          new_user.username = message.from.username
          new_user.notify_solution = true
        end

        sender = Sender.new(message, user)

        # if WatchDog.start + 15 < Time.now
        #   WatchDog.start = Time.now + 15
        #   raise Faraday::ConnectionFailed, 'custom error for watchdog test'
        # end

        begin
          case message
          when Telegram::Bot::Types::Message
            if ReplyPool.pool[user.chat_id]
              ReplyPool.call_with(user.chat_id, message)
              next
            end

            case message.text
            when '/start'
              user.update(notify_solution: true)
              sender.default_response
            when user.t('pool_data'), '/pool_data'
              sender.send_message(NotifyApi.pool_data(user), with_replacing: true)
            when user.t('notify_on'), '/notify_on'
              if Looper.add_user(user)
                sender.send_message(user.t('start_notify'), with_replacing: true)
              else
                sender.send_message(user.t('already_notify'))
                sender.send_message(NotifyApi.last_giver_info(user: user), with_replacing: true)
              end
            when user.t('notify_off'), '/notify_off'
              Looper.remove_user(user)
              sender.send_message(user.t('stop_notify'), with_replacing: true)
            when user.t('change_time_zone'), '/change_tz'
              current_time_zone = user.time_zone.to_i
              sender.with_keyboard_close(user.t('change_tz_info', current: current_time_zone))
              ReplyPool.new(user).change_time_zone
            when user.t('set_wallet'), '/set_wallet'
              sender.with_keyboard_close(user.t('type_wallet'))
              ReplyPool.new(user).set_wallet
            # when user.t('wallet_data'), '/wallet_data'
            #   if user.wallet
            #     sender.send_message(Api::WalletData.perform(user.wallet), with_replacing: true)
            #   else
            #     sender.default_response(user.t('add_wallet_in_settings'))
            #   end
            when user.t('settings')
              sender.settings_response
            when user.t('profit_calculating'), '/profit_calculating'
              sender.with_keyboard_close(user.t('profit_calculating_info'))
              ReplyPool.new(user).profit_calculating
            when user.t('switch_language'), '/switch_language'
              new_locale = user.locale.to_s == 'ru' ? :en : :ru
              user.update(locale: new_locale)
              log "User #{user.debug_user_info} change language to #{new_locale}"
              sender.settings_response(user.t('language_changed'))
            when user.t('back_to_main_menu')
              sender.default_response
            else
              log "#{user.debug_user_info} user send text: #{message.text}"
              sender.default_response
            end
          when Telegram::Bot::Types::ChatMemberUpdated
            case message.new_chat_member&.status
            when 'kicked'
              user.update(notify_solution: false)
              log "User #{user.debug_user_info} kicked"
            when 'member'
              log "User join again with restarting bot #{user.debug_user_info}"
            end
          else
            log "New user action #{message.class}\n ----------------->\n#{message}"
            sender.default_response
          end
        rescue StandardError => e
          log e.message
          log e.full_message
          sender.send_message(user.t('unknown_error'))
        end
      end
    end
  end

  def self.on_global_error
    Looper.stop_all
  end
end
