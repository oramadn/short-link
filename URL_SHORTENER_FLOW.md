# URL Shortener Flow

This document outlines the encoding and decoding flows of the URL shortener application.

## Encoding Flow: Creating a Short URL

The process of creating a short URL from a long URL is handled by the `Api::V1::UrlsController#encode` action.

1.  **Receive Long URL**: The user sends a POST request to `/api/v1/encode` with the `url` parameter containing the long URL to be shortened.

2.  **Find or Create URL**:
    *   The application uses `Url.find_or_create_by_url(long_url)` to check if the URL already exists in the database.
    *   Before validation, the `long_url` is normalized to ensure a consistent format (e.g., adding `http://` if missing, downcasing the host).
    *   A SHA256 hash of the normalized URL is generated and stored in `long_url_hash`. This hash is used to quickly look up existing URLs.
    *   If a URL with the same hash exists, it's returned. Otherwise, a new `Url` record is created.

3.  **Generate Short Code**:
    *   After a new `Url` record is created, a unique `short_code` is generated using the `Base62Converter.encode(id)` method, which converts the record's primary key (`id`) into a Base62 string.
    *   The `short_code` is then saved to the `Url` record.

4.  **Cache URL**:
    *   A background job, `CacheUrlJob`, is enqueued to cache the mapping between the `short_code` and the `long_url`.
    *   This job writes the `long_url` to the Rails cache with the `short_code` as the key, with an expiration of 24 hours.

5.  **Return Short URL**: The API responds with a JSON object containing the `short_url` (e.g., `http://example.com/aBc123`) and the `short_code`.

## Decoding Flow: Resolving a Short URL

The process of retrieving the original long URL from a short code is handled by the `Api::V1::UrlsController#decode` action.

1.  **Receive Short Code**: The user sends a GET request to `/api/v1/decode/:short_code` with the `short_code`.

2.  **Look Up in Cache**:
    *   The application first attempts to find the `long_url` in the cache using `Rails.cache.read("url_code:#{short_code}")`.
    *   If found, the cached `long_url` is returned immediately.

3.  **Look Up in Database**:
    *   If the `long_url` is not in the cache, the application queries the database for a `Url` record with the given `short_code`.
    *   If a record is found, the `long_url` is retrieved.

4.  **Cache URL (if needed)**:
    *   If the `long_url` was found in the database (cache miss), a `CacheUrlJob` is enqueued to cache the `short_code` and `long_url` for future requests.

5.  **Return Long URL**: The API responds with a JSON object containing the `long_url`. If the `short_code` is not found, a `404 Not Found` error is returned.
