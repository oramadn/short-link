require "digest"

class Url < ApplicationRecord
  validates :long_url, presence: true
  validates :long_url_hash, uniqueness: true

  before_validation :normalize_url, if: :long_url_changed?
  before_validation :generate_long_url_hash, if: :long_url_changed?

  after_create :generate_short_code

  def self.find_or_create_by_url(long_url)
    url_hash = Digest::SHA256.hexdigest(long_url)
    find_by(long_url_hash: url_hash) || create!(long_url: long_url)
  rescue ActiveRecord::RecordNotUnique
    find_by!(long_url_hash: url_hash)
  end

  def self.find_long_url(short_code)
    cached = Rails.cache.read("url_code:#{short_code}")
    return cached if cached

    url = find_by(short_code: short_code)
    if url
      CacheUrlJob.perform_later(short_code, url.long_url)
      url.long_url
    end
  end

  private

  def normalize_url
    return if long_url.blank?

    uri = parse_uri(long_url.strip)
    return unless uri

    uri.scheme ||= "http"
    uri.host = uri.host&.downcase
    uri.path = "" if uri.path == "/"

    self.long_url = uri.to_s
  end

  def parse_uri(url)
    uri = URI.parse(url)
    uri.scheme.nil? ? URI.parse("http://#{url}") : uri
  rescue URI::InvalidURIError
    nil
  end

  def generate_long_url_hash
    self.long_url_hash = Digest::SHA256.hexdigest(long_url)
  end

  def generate_short_code
    update_column(:short_code, Base62Converter.encode(id))
  end
end
