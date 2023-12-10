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

    def initialize(headers, payload, primary_signature_key: nil, secondary_signature_key: nil)
      @payload                 = payload
      @timestamp               = headers['BOX-DELIVERY-TIMESTAMP'].to_s
      @primary_signature_key   = primary_signature_key.to_s
      @secondary_signature_key = secondary_signature_key.to_s
      @primary_signature       = headers['BOX-SIGNATURE-PRIMARY']
      @secondary_signature     = headers['BOX-SIGNATURE-SECONDARY']
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
      digest = OpenSSL::HMAC.digest("SHA256", key, "#{payload}#{timestamp}")
      Base64.strict_encode64(digest)
    end

    private

    def current_time
      Time.now.utc
    end

    def delivery_time
      Time.parse(timestamp).utc
    rescue ArgumentError
      raise BoxrError.new(boxr_message: "Webhook authenticity not verified: invalid timestamp")
    end

    def message_age
      current_time - delivery_time
    end
  end
end
