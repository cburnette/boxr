module Boxr
	class Client

		def file_tasks(file_id, fields: [])
			uri = "#{FILES_URI}/#{file_id}/tasks"
			query = build_fields_query(fields, TASK_FIELDS_QUERY)

			tasks, response = get uri, query: query
			tasks["entries"]
		end

		def create_task(file_id, action: :review, message: nil, due_at: nil)
			attributes = {item: {type: :file, id: file_id}}
			attributes[:action] = action unless action.nil?
			attributes[:message] = message unless message.nil?
			attributes[:due_at] = due_at.to_datetime.rfc3339 unless due_at.nil?

			new_task, response = post TASKS_URI, attributes
			new_task
		end

		def task(task_id)
			uri = "#{TASKS_URI}/#{task_id}"
			task, response = get uri
			task
		end

		def update_task(task_id, action: :review, message: nil, due_at: nil)
			uri = "#{TASKS_URI}/#{task_id}"
			attributes = {}
			attributes[:action] = action unless action.nil?
			attributes[:message] = message unless message.nil?
			attributes[:due_at] = due_at.to_datetime.rfc3339 unless due_at.nil?

			task, response = put uri, attributes
			task
		end

		def delete_task(task_id)
			uri = "#{TASKS_URI}/#{task_id}"
			result, response = delete uri
			result
		end

		def task_assignments(task_id)
			uri = "#{TASKS_URI}/#{task_id}/assignments"
			assignments, response = get uri
			assignments['entries']
		end

		def create_task_assignment(task_id, assign_to_id: nil, assign_to_login: nil)
			attributes = {task: {type: :task, id: "#{task_id}"}}
			
			attributes[:assign_to] = {} 
			attributes[:assign_to][:login] = assign_to_login unless assign_to_login.nil?
			attributes[:assign_to][:id] = assign_to_id unless assign_to_id.nil?

			new_task_assignment, response = post TASK_ASSIGNMENTS_URI, attributes
			new_task_assignment
		end

		def task_assignment(task_id)
			uri = "#{TASK_ASSIGNMENTS_URI}/#{task_id}"
			task_assignment, response = get uri
			task_assignment
		end

		def delete_task_assignment(task_id)
			uri = "#{TASK_ASSIGNMENTS_URI}/#{task_id}"
			result, response = delete uri
			result
		end

		def update_task_assignment(task_id, message: nil, resolution_state: nil)
			uri = "#{TASK_ASSIGNMENTS_URI}/#{task_id}"
			attributes = {}
			attributes[:message] = message unless message.nil?
			attributes[:resolution_state] = resolution_state unless resolution_state.nil?

			updated_task, respons = put uri, attributes
			updated_task
		end

	end
end