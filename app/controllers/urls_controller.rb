class UrlsController < ApplicationController
  def encode
    long_url = params[:url]
    return render json: { error: "URL is required" }, status: :bad_request if long_url.blank?

    url_hash = Digest::SHA256.hexdigest(long_url)

    @url = Url.find_by(long_url_hash: url_hash)

    if @url.nil?
      begin
        @url = Url.create!(long_url: long_url)
      rescue ActiveRecord::RecordNotUnique
        @url = Url.find_by!(long_url_hash: url_hash)
      end
    end

    CacheUrlJob.perform_later(@url.short_code, @url.long_url)

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
      CacheUrlJob.perform_later(short_code, @url.long_url)
      render json: { long_url: @url.long_url }, status: :ok
    else
      render json: { error: "Short code not found" }, status: :not_found
    end
  end
end
