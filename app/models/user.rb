# frozen_string_literal: true

class User < ApplicationRecord
  def debug_user_info
    "#{tg_id} #{first_name} #{username}".strip
  end

  def f_time(time_for_formatting = Time.now)
    format_time(time_for_formatting.utc.in_time_zone(time_zone))
  end

  def t(key, **args)
    I18n.t(key, **args.merge(locale: locale || :en))
  end

  def self.notified
    where(notify_solution: true)
  end
end
