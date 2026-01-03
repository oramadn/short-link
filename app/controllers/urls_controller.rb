class UrlsController < ApplicationController
  def encode
    long_url = params[:url]
    return render json: { error: "URL is required" }, status: :bad_request if long_url.blank?

    url_hash = Digest::SHA256.hexdigest(long_url)

    @url = Url.find_by(long_url_hash: url_hash)

    if @url.nil?
      @url = Url.create(long_url: long_url)
    end

    Rails.cache.write("url_code:#{@url.short_code}", @url.long_url, expires_in: 24.hours)

    render json: {
      short_url: "#{request.base_url}/#{@url.short_code}",
      short_code: @url.short_code
    }, status: :ok
  end

  def decode
    short_code = params[:short_code]

    cached_url = Rails.cache.read("url_code:#{short_code}")

    if cached_url
      return render json: { long_url: cached_url }, status: :ok
    end

    @url = Url.find_by(short_code: short_code)

    if @url
      Rails.cache.write("url_code:#{short_code}", @url.long_url, expires_in: 24.hours)
      render json: { long_url: @url.long_url }, status: :ok
    else
      render json: { error: "Short code not found" }, status: :not_found
    end
  end
end
