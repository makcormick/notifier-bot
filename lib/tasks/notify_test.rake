# frozen_string_literal: true

require File.expand_path('../../config/environment', __dir__)

desc 'Start tg notifier'
task :start do
  BotRuner.go!
end
