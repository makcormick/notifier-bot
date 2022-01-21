# frozen_string_literal: true

class Config
  class << self
    def token
      @token ||= ENV['token']
    end
  end
end
