# frozen_string_literal: true

module Boxr
  class WebhookValidator
    attr_reader(
      :payload,
      :primary_signature,
      :primary_signature_key,
      :secondary_signature,
      :secondary_signature_key,
      :timestamp
    )

    MAXIMUM_MESSAGE_AGE = 600 # 10 minutes (in seconds)

    def initialize(headers, payload, primary_signature_key: ENV['BOX_PRIMARY_SIGNATURE_KEY'], secondary_signature_key: ENV['BOX_SECONDARY_SIGNATURE_KEY'])
      @payload                 = payload
      @timestamp               = headers['Box-Delivery-Timestamp'].to_s
      @primary_signature_key   = primary_signature_key.to_s
      @secondary_signature_key = secondary_signature_key.to_s
      @primary_signature       = headers['Box-Signature-Primary']
      @secondary_signature     = headers['Box-Signature-Secondary']
    end

    def valid_message?
      verify_delivery_timestamp && verify_signature
    end

    def verify_delivery_timestamp
      message_age < MAXIMUM_MESSAGE_AGE
    end

    def verify_signature
      generate_signature(primary_signature_key) == primary_signature || generate_signature(secondary_signature_key) == secondary_signature
    end

    def generate_signature(key)
      message_as_bytes = (payload.bytes + timestamp.bytes).pack('U')
      digest = OpenSSL::HMAC.hexdigest('SHA256', key, message_as_bytes)
      Base64.encode64(digest)
    end

    private

    def current_time
      Time.current
    end

    def delivery_time
      Time.parse(timestamp)
    rescue ArgumentError
      raise('Webhook authenticity not verified: invalid timestamp')
    end

    def message_age
      current_time - delivery_time
    end
  end
end
