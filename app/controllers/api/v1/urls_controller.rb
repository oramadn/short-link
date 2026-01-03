class Api::V1::UrlsController < ApplicationController
  def encode
    long_url = params[:url]
    return render json: { error: "URL is required" }, status: :bad_request if long_url.blank?

    @url = Url.find_or_create_by_url(long_url)
    CacheUrlJob.perform_later(@url.short_code, @url.long_url)

    render json: {
      short_url: "#{request.base_url}/#{@url.short_code}",
      short_code: @url.short_code
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("Encode error: #{e.message}")
    render json: { error: "An error occurred" }, status: :internal_server_error
  end

  def decode
    short_code = params[:short_code]
    long_url = Url.find_long_url(short_code)

    if long_url
      render json: { long_url: long_url }, status: :ok
    else
      render json: { error: "Short code not found" }, status: :not_found
    end
  end
end
