class CacheUrlJob < ApplicationJob
  queue_as :default

  def perform(short_code, long_url)
    Rails.cache.write("url_code:#{short_code}", long_url, expires_in: 24.hours)
  end
end
