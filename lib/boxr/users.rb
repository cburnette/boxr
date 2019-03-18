# frozen_string_literal: true

module Boxr
  class Client
    def current_user(fields: [])
      uri = "#{USERS_URI}/me"
      query = build_fields_query(fields, USER_FIELDS_QUERY)

      user, response = get(uri, query: query)
      user
    end
    alias me current_user

    def user_from_id(user_id, fields: [])
      user_id = ensure_id(user_id)
      uri = "#{USERS_URI}/#{user_id}"
      query = build_fields_query(fields, USER_FIELDS_QUERY)

      user, response = get(uri, query: query)
      user
    end
    alias user user_from_id

    def all_users(filter_term: nil, fields: [], offset: nil, limit: nil)
      uri = USERS_URI
      query = build_fields_query(fields, USER_FIELDS_QUERY)
      query[:filter_term] = filter_term unless filter_term.nil?

      if offset.nil? || limit.nil?
        users = get_all_with_pagination(uri, query: query, offset: 0, limit: DEFAULT_LIMIT)
      else
        query[:offset] = offset
        query[:limit] = limit

        users, response = get(uri, query: query)
        users['entries']
      end
    end

    def create_user(name, login: nil, role: nil, language: nil, is_sync_enabled: nil, job_title: nil,
                    phone: nil, address: nil, space_amount: nil, tracking_codes: nil,
                    can_see_managed_users: nil, is_external_collab_restricted: nil, status: nil, timezone: nil,
                    is_exempt_from_device_limits: nil, is_exempt_from_login_verification: nil,
                    is_platform_access_only: nil)

      uri = USERS_URI
      attributes = { name: name }
      attributes[:login] = login unless login.nil? # login is not required for platform users, so needed to make this optional
      attributes[:role] = role unless role.nil?
      attributes[:language] = language unless language.nil?
      attributes[:is_sync_enabled] = is_sync_enabled unless is_sync_enabled.nil?
      attributes[:job_title] = job_title unless job_title.nil?
      attributes[:phone] = phone unless phone.nil?
      attributes[:address] = address unless address.nil?
      attributes[:space_amount] = space_amount unless space_amount.nil?
      attributes[:tracking_codes] = tracking_codes unless tracking_codes.nil?
      attributes[:can_see_managed_users] = can_see_managed_users unless can_see_managed_users.nil?
      attributes[:is_external_collab_restricted] = is_external_collab_restricted unless is_external_collab_restricted.nil?
      attributes[:status] = status unless status.nil?
      attributes[:timezone] = timezone unless timezone.nil?
      attributes[:is_exempt_from_device_limits] = is_exempt_from_device_limits unless is_exempt_from_device_limits.nil?
      attributes[:is_exempt_from_login_verification] = is_exempt_from_login_verification unless is_exempt_from_login_verification.nil?
      attributes[:is_platform_access_only] = is_platform_access_only unless is_platform_access_only.nil?

      new_user, response = post(uri, attributes)
      new_user
    end

    def update_user(user, notify: nil, enterprise: true, name: nil, role: nil, language: nil, is_sync_enabled: nil,
                    job_title: nil, phone: nil, address: nil, space_amount: nil, tracking_codes: nil,
                    can_see_managed_users: nil, status: nil, timezone: nil, is_exempt_from_device_limits: nil,
                    is_exempt_from_login_verification: nil, is_exempt_from_reset_required: nil, is_external_collab_restricted: nil)

      user_id = ensure_id(user)
      uri = "#{USERS_URI}/#{user_id}"
      query = { notify: notify } unless notify.nil?

      attributes = {}
      attributes[:enterprise] = nil if enterprise.nil? # this is a special condition where setting this to nil means to roll this user out of the enterprise
      attributes[:name] = name unless name.nil?
      attributes[:role] = role unless role.nil?
      attributes[:language] = language unless language.nil?
      attributes[:is_sync_enabled] = is_sync_enabled unless is_sync_enabled.nil?
      attributes[:job_title] = job_title unless job_title.nil?
      attributes[:phone] = phone unless phone.nil?
      attributes[:address] = address unless address.nil?
      attributes[:space_amount] = space_amount unless space_amount.nil?
      attributes[:tracking_codes] = tracking_codes unless tracking_codes.nil?
      attributes[:can_see_managed_users] = can_see_managed_users unless can_see_managed_users.nil?
      attributes[:status] = status unless status.nil?
      attributes[:timezone] = timezone unless timezone.nil?
      attributes[:is_exempt_from_device_limits] = is_exempt_from_device_limits unless is_exempt_from_device_limits.nil?
      attributes[:is_exempt_from_login_verification] = is_exempt_from_login_verification unless is_exempt_from_login_verification.nil?
      attributes[:is_exempt_from_reset_required] = is_exempt_from_reset_required unless is_exempt_from_reset_required.nil?
      attributes[:is_external_collab_restricted] = is_external_collab_restricted unless is_external_collab_restricted.nil?

      updated_user, response = put(uri, attributes, query: query)
      updated_user
    end

    def delete_user(user, notify: nil, force: nil)
      user_id = ensure_id(user)
      uri = "#{USERS_URI}/#{user_id}"
      query = {}
      query[:notify] = notify unless notify.nil?
      query[:force] = force unless force.nil?

      result, response = delete(uri, query: query)
      result
    end

    # As of writing, API only supports a root source folder (0)
    def move_users_folder(user, source_folder = 0, destination_user)
      user_id = ensure_id(user)
      destination_user_id = ensure_id(destination_user)
      source_folder_id = ensure_id(source_folder)
      uri = "#{USERS_URI}/#{user_id}/folders/#{source_folder_id}"
      attributes = {owned_by: {id: destination_user_id}}

      folder, response = put(uri, attributes)
      folder
    end

    def email_aliases_for_user(user)
      user_id = ensure_id(user)
      uri = "#{USERS_URI}/#{user_id}/email_aliases"

      aliases, response = get(uri)
      aliases['entries']
    end

    def add_email_alias_for_user(user, email)
      user_id = ensure_id(user)
      uri = "#{USERS_URI}/#{user_id}/email_aliases"
      attributes = {email: email}

      updated_user, response = post(uri, attributes)
      updated_user
    end

    def remove_email_alias_for_user(user, email_alias)
      user_id = ensure_id(user)
      email_alias_id = ensure_id(email_alias)
      uri = "#{USERS_URI}/#{user_id}/email_aliases/#{email_alias_id}"

      result, response = delete(uri)
      result
    end
  end
end
