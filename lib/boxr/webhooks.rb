module Boxr
  class Client

    def get_webhook_from_id(webhook_id)

      webhook_id = ensure_id(webhook_id)
      uri = "#{WEBHOOKS_URI}/#{webhook_id}"

      webhooks, response = get(uri)
      webhooks
    end
    
    def all_webhooks(marker: nil,limit: nil))
      
      uri = "#{WEBHOOKS_URI}"
      
      if offset.nil? || limit.nil?
        webhooks = get_all_with_pagination(uri, query: nil, offset: 0, limit: DEFAULT_LIMIT)
      else
        query[:offset] = offset
        query[:limit] = limit
        
        webhooks, response = get(uri, query: query)
        webhooks['entries']
      end
    end
      
    def create_webhook(targer_id,target_type,url,events)
         attributes = {target: {id: target_id, type: target_type}}
         attributes = [:address] = url
         arreibutes = [:triggers] = events
         
         webhooks, response = post(WEBHOOKS_URI,attributes)
         webhooks

    end
end
