require "test_helper"

class Api::V1::UrlsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @url = Url.create(long_url: "http://example-fixture.com/1")
  end

  test "should encode url and return short url" do
    post "/api/v1/encode", params: { url: "http://test.com" }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["short_url"]
    assert_not_nil json_response["short_code"]
    assert json_response["short_url"].include?(json_response["short_code"])
  end

  test "should return bad request if url is missing for encode" do
    post "/api/v1/encode", params: { url: "" }
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal "URL is required", json_response["error"]
  end

  test "should return existing short url if url already exists" do
    post "/api/v1/encode", params: { url: @url.long_url }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal "#{request.base_url}/#{@url.short_code}", json_response["short_url"]
  end

  test "should decode short code and return long url" do
    get "/api/v1/decode/#{@url.short_code}"
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal @url.long_url, json_response["long_url"]
  end

  test "should return not found if short code does not exist for decode" do
    get "/api/v1/decode/nonexistent"
    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Short code not found", json_response["error"]
  end
end
