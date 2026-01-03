require "digest"

class Url < ApplicationRecord
  validates :long_url, presence: true

  before_validation :normalize_url, if: :long_url_changed?
  before_validation :generate_long_url_hash, if: :long_url_changed?

  after_create :generate_short_code

  private

  def normalize_url
    return if long_url.blank?

    clean_url = long_url.strip

    begin
      uri = URI.parse(clean_url)

      if uri.scheme.nil?
        clean_url = "http://#{clean_url}"
        uri = URI.parse(clean_url)
      end

      uri.host = uri.host.downcase

      uri.path = "" if uri.path == "/"

      self.long_url = uri.to_s
    rescue URI::InvalidURIError
    end
  end

  def generate_long_url_hash
    self.long_url_hash = Digest::SHA256.hexdigest(long_url)
  end

  def generate_short_code
    code = Base62Converter.encode(self.id)

    update_column(:short_code, code)
  end
end
