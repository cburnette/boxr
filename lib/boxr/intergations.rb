module Boxr
  class Client

    def assign(user,id)
        attributes = {assignee: {type: "user", id: user},app_integration: {type: "app_integration", id: id}}
        body = {JSON.dump(attributes)}

        assignment_info, response post(INTEGRATION, attributes)
        assignment_info.entries[0]
    end
  end
end