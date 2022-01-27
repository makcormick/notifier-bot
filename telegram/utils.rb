# frozen_string_literal: true

module Utils
  def just_time(time)
    time.ago_in_words.gsub(' ago', '')
  end

  def format_time(time = Time.now, time_zone: nil)
    if time_zone
      time.in_time_zone(time_zone).strftime('%H:%M:%S %d.%m.%Y (%z)')
    else
      time.strftime('%H:%M:%S %d.%m.%Y (%z)')
    end
  end

  def to_gh(str)
    (str.to_f / (10**9)).round(3)
  end

  def to_th(str)
    (str.to_f / (10**12)).round(3)
  end

  def to_ph(str)
    (str.to_f / (10**15)).round(3)
  end

  def b(text)
    "<b>#{text}</b>"
  end

  def u(text)
    "<u>#{text}</u>"
  end

  def just(text, num = 8)
    text.to_s.rjust(num, ' ')
  end

  def integer?(str)
    /\A[+-]?\d+\z/.match?(str)
  end

  def request(url)
    uri = URI(url)
    Net::HTTP.get_response(uri).body
  end

  def request_json(url, log_text: nil)
    print('.') if log_text
    handle do
      data = JSON.parse(request(url))
      puts(log_text) if log_text
      data
    end
  end

  def request_html(url, log_text: nil)
    print('.') if log_text
    handle do
      data = Nokogiri::HTML(request(url))
      puts(log_text) if log_text
      data
    end
  end

  def handle(times = 5)
    res = nil

    times.times do |try_num|
      res = yield
      break
    rescue StandardError => e
      log "Try ##{try_num + 1} with error. #{e.message.truncate(200)}\nFull message\n#{e.full_message.truncate(1200)}"
      log e.backtrace.first(15).join("\n")
      log "Sleep 2 seconds\n********"
      sleep(2)
    end

    res
  end

  def center_log(text)
    puts "#{format_time}: #{text}".center(90, '*')
  end

  def log(text)
    puts("#{format_time}: #{text}")
  end

  def mem_test
    start_mb = GetProcessMem.new.mb
    log("Memory start-point #{start_mb}")
    yield
    end_mb = GetProcessMem.new.mb
    log("Memory end-point #{end_mb}")
    log("Diff #{end_mb - start_mb}")
  end
end
