require "digest"

class Url < ApplicationRecord
  validates :long_url, presence: true
  before_validation :generate_long_url_hash, if: :long_url_changed?

  after_create :generate_short_code

  private

  def generate_long_url_hash
    self.long_url_hash = Digest::SHA256.hexdigest(long_url)
  end

  def generate_short_code
    code = Base62Converter.encode(self.id)

    update_column(:short_code, code)
  end
end
