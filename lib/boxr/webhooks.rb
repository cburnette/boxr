# frozen_string_literal: true

module Boxr
  class Client
    def create_webhook(target_id, target_type, triggers, address)
      attributes = { target: { id: target_id, type: target_type }, triggers: triggers,
                     address: address }
      new_webhook, = post(WEBHOOKS_URI, attributes)
      new_webhook
    end

    def get_webhooks(marker: nil, limit: nil)
      query_params = { marker: marker, limit: limit }.compact
      webhooks, = get(WEBHOOKS_URI, query: query_params)
      webhooks
    end

    def get_webhook(webhook)
      webhook_id = ensure_id(webhook)
      uri = "#{WEBHOOKS_URI}/#{webhook_id}"
      webhook, = get(uri)
      webhook
    end

    def update_webhook(webhook, attributes = {})
      webhook_id = ensure_id(webhook)
      uri = "#{WEBHOOKS_URI}/#{webhook_id}"
      updated_webhook, = put(uri, attributes)
      updated_webhook
    end

    def delete_webhook(webhook)
      webhook_id = ensure_id(webhook)
      uri = "#{WEBHOOKS_URI}/#{webhook_id}"
      result, = delete(uri)
      result
    end
  end
end
