# frozen_string_literal: true

module Boxr
  class Client
    def file_tasks(file, fields: [])
      file_id = ensure_id(file)
      uri = "#{FILES_URI}/#{file_id}/tasks"
      query = build_fields_query(fields, TASK_FIELDS_QUERY)

      tasks, response = get(uri, query: query)
      tasks.entries
    end

    def create_task(file, action: :review, message: nil, due_at: nil)
      file_id = ensure_id(file)
      attributes = { item: { type: :file, id: file_id } }
      attributes[:action] = action unless action.nil?
      attributes[:message] = message unless message.nil?
      attributes[:due_at] = due_at.to_datetime.rfc3339 unless due_at.nil?

      new_task, response = post(TASKS_URI, attributes)
      new_task
    end

    def task_from_id(task_id)
      task_id = ensure_id(task_id)
      uri = "#{TASKS_URI}/#{task_id}"
      task, response = get(uri)
      task
    end
    alias task task_from_id

    def update_task(task, action: :review, message: nil, due_at: nil)
      task_id = ensure_id(task)
      uri = "#{TASKS_URI}/#{task_id}"
      attributes = {}
      attributes[:action] = action unless action.nil?
      attributes[:message] = message unless message.nil?
      attributes[:due_at] = due_at.to_datetime.rfc3339 unless due_at.nil?

      task, response = put(uri, attributes)
      task
    end

    def delete_task(task)
      task_id = ensure_id(task)
      uri = "#{TASKS_URI}/#{task_id}"
      result, response = delete(uri)
      result
    end

    def task_assignments(task)
      task_id = ensure_id(task)
      uri = "#{TASKS_URI}/#{task_id}/assignments"
      assignments, response = get(uri)
      assignments['entries']
    end

    def create_task_assignment(task, assign_to: nil, assign_to_login: nil)
      task_id = ensure_id(task)
      assign_to_id = ensure_id(assign_to)
      attributes = { task: { type: :task, id: task_id.to_s } }

      attributes[:assign_to] = {}
      attributes[:assign_to][:login] = assign_to_login unless assign_to_login.nil?
      attributes[:assign_to][:id] = assign_to_id unless assign_to_id.nil?

      new_task_assignment, response = post(TASK_ASSIGNMENTS_URI, attributes)
      new_task_assignment
    end

    def task_assignment(task)
      task_id = ensure_id(task)
      uri = "#{TASK_ASSIGNMENTS_URI}/#{task_id}"
      task_assignment, response = get(uri)
      task_assignment
    end

    def delete_task_assignment(task)
      task_id = ensure_id(task)
      uri = "#{TASK_ASSIGNMENTS_URI}/#{task_id}"
      result, response = delete(uri)
      result
    end

    def update_task_assignment(task, message: nil, resolution_state: nil)
      task_id = ensure_id(task)
      uri = "#{TASK_ASSIGNMENTS_URI}/#{task_id}"
      attributes = {}
      attributes[:message] = message unless message.nil?
      attributes[:resolution_state] = resolution_state unless resolution_state.nil?

      updated_task, response = put(uri, attributes)
      updated_task
    end
  end
end
