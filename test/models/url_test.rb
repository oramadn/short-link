require "test_helper"

class UrlTest < ActiveSupport::TestCase
  test "should be valid with a long_url" do
    url = Url.new(long_url: "http://example.com")
    assert url.valid?
  end

  test "should be invalid without a long_url" do
    url = Url.new(long_url: nil)
    assert_not url.valid?
  end

  test "should normalize url before validation" do
    url = Url.create(long_url: "  http://EXAMPLE.com/path/  ")
    assert_equal "http://example.com/path/", url.long_url
  end

  test "should add http scheme if not present" do
    url = Url.create(long_url: "example.com")
    assert_equal "http://example.com", url.long_url
  end

  test "should generate long_url_hash before validation" do
    long_url = "http://example.com"
    url = Url.new(long_url: long_url)
    url.valid?
    assert_equal Digest::SHA256.hexdigest(long_url), url.long_url_hash
  end

  test "should generate short_code after create" do
    url = Url.create(long_url: "http://example.com")
    assert_not_nil url.short_code
    assert_equal Base62Converter.encode(url.id), url.short_code
  end

  test "long_url_hash should be unique" do
    Url.create(long_url: "http://example.com")
    url2 = Url.new(long_url: "http://example.com")
    assert_not url2.valid?
  end

  test ".find_or_create_by_url for a new url" do
    long_url = "http://example-new.com"
    assert_difference "Url.count", 1 do
      Url.find_or_create_by_url(long_url)
    end
  end

  test ".find_or_create_by_url for an existing url" do
    url = Url.create(long_url: "http://example-existing.com")
    assert_no_difference "Url.count" do
      found_url = Url.find_or_create_by_url("http://example-existing.com")
      assert_equal url, found_url
    end
  end

  test ".find_long_url with a valid short_code" do
    url = Url.create(long_url: "http://example.com/very/long/url")
    found_long_url = Url.find_long_url(url.short_code)
    assert_equal "http://example.com/very/long/url", found_long_url
  end

  test ".find_long_url with an invalid short_code" do
    assert_nil Url.find_long_url("invalidcode")
  end

  test ".find_long_url enqueues a caching job" do
    url = Url.create(long_url: "http://example-cached.com")
    assert_enqueued_with(job: CacheUrlJob, args: [ url.short_code, url.long_url ]) do
      Url.find_long_url(url.short_code)
    end
  end

  test "handles URI parsing errors gracefully" do
    url = Url.new(long_url: "http://[::1]:.com")
    assert url.valid?
  end
end
