class CacheUrlJob < ApplicationJob
  queue_as :default

  # The short code and long URL are written to the Rails cache with a 24-hour expiration.
  # @param short_code [String] The short code to be cached.
  # @param long_url [String] The long URL corresponding to the short code.
  def perform(short_code, long_url)
    Rails.cache.write("url_code:#{short_code}", long_url, expires_in: 24.hours)
  end
end
