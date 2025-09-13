require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_file) { Hashie::Mash.new(id: '12345', name: 'test.txt') }
  let(:test_task) { Hashie::Mash.new(id: 'task123', action: 'review', message: 'Please review') }
  let(:test_task_assignment) { Hashie::Mash.new(id: 'assignment123', task: test_task) }
  let(:test_user) { Hashie::Mash.new(id: 'user123', login: 'user@example.com') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_tasks_response) do
    BoxrMash.new(entries: [test_task, test_task])
  end
  let(:mock_assignments_response) do
    BoxrMash.new('entries' => [test_task_assignment, test_task_assignment])
  end
  let(:due_at) { Time.now + (7 * 24 * 60 * 60) }

  describe '#file_tasks' do
    before do
      allow(client).to receive(:get).and_return([mock_tasks_response, mock_response])
    end

    it 'retrieves file tasks' do
      result = client.file_tasks(test_file)
      expect(result).to eq([test_task, test_task])
    end

    it 'calls get with correct URI' do
      client.file_tasks(test_file)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::FILES_URI}/12345/tasks",
        query: {}
      )
    end

    it 'retrieves file tasks with fields' do
      client.file_tasks(test_file, fields: %i[action message due_at])
      expect(client).to have_received(:get).with(
        anything,
        query: anything
      )
    end

    it 'accepts file as string ID' do
      result = client.file_tasks('12345')
      expect(result).to eq([test_task, test_task])
    end
  end

  describe '#create_task' do
    before do
      allow(client).to receive(:post).and_return(test_task)
    end

    it 'creates task with default action' do
      result = client.create_task(test_file)
      expect(result).to eq(test_task)
    end

    it 'creates task with custom action' do
      result = client.create_task(test_file, action: :complete)
      expect(result).to eq(test_task)
    end

    it 'creates task with message' do
      result = client.create_task(test_file, message: 'Please review this file')
      expect(result).to eq(test_task)
    end

    it 'creates task with due_at' do
      result = client.create_task(test_file, due_at: due_at)
      expect(result).to eq(test_task)
    end

    it 'creates task with all parameters' do
      result = client.create_task(test_file, action: :review, message: 'Review needed', due_at: due_at)
      expect(result).to eq(test_task)
    end

    it 'calls post with correct attributes' do
      client.create_task(test_file, action: :review, message: 'test', due_at: due_at)
      expect(client).to have_received(:post).with(
        Boxr::Client::TASKS_URI,
        hash_including(
          item: { type: :file, id: '12345' },
          action: :review,
          message: 'test',
          due_at: due_at.to_datetime.rfc3339
        )
      )
    end

    it 'accepts file as string ID' do
      result = client.create_task('12345', action: :review)
      expect(result).to eq(test_task)
    end

    it 'omits nil parameters from attributes' do
      client.create_task(test_file, action: :review)
      expect(client).to have_received(:post).with(
        Boxr::Client::TASKS_URI,
        hash_including(
          item: { type: :file, id: '12345' },
          action: :review
        )
      )
    end
  end

  describe '#task_from_id' do
    before do
      allow(client).to receive(:get).and_return(test_task)
    end

    it 'retrieves task by ID' do
      result = client.task_from_id('task123')
      expect(result).to eq(test_task)
    end

    it 'calls get with correct URI' do
      client.task_from_id('task123')
      expect(client).to have_received(:get).with("#{Boxr::Client::TASKS_URI}/task123")
    end

    it 'accepts task as object' do
      result = client.task_from_id(test_task)
      expect(result).to eq(test_task)
    end
  end

  describe '#task (alias)' do
    before do
      allow(client).to receive(:get).and_return(test_task)
    end

    it 'calls task_from_id' do
      result = client.task('task123')
      expect(result).to eq(test_task)
    end
  end

  describe '#update_task' do
    before do
      allow(client).to receive(:put).and_return(test_task)
    end

    it 'updates task with action' do
      result = client.update_task(test_task, action: :complete)
      expect(result).to eq(test_task)
    end

    it 'updates task with message' do
      result = client.update_task(test_task, message: 'Updated message')
      expect(result).to eq(test_task)
    end

    it 'updates task with due_at' do
      result = client.update_task(test_task, due_at: due_at)
      expect(result).to eq(test_task)
    end

    it 'updates task with all parameters' do
      result = client.update_task(test_task, action: :complete, message: 'Done', due_at: due_at)
      expect(result).to eq(test_task)
    end

    it 'calls put with correct URI and attributes' do
      client.update_task(test_task, action: :complete, message: 'test')
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::TASKS_URI}/task123",
        hash_including(action: :complete, message: 'test')
      )
    end

    it 'accepts task as string ID' do
      result = client.update_task('task123', action: :complete)
      expect(result).to eq(test_task)
    end

    it 'omits nil parameters from attributes' do
      client.update_task(test_task, action: :complete)
      expect(client).to have_received(:put).with(
        anything,
        hash_including(action: :complete)
      )
    end
  end

  describe '#delete_task' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'deletes task by object' do
      result = client.delete_task(test_task)
      expect(result).to eq({})
    end

    it 'deletes task by ID' do
      result = client.delete_task('task123')
      expect(result).to eq({})
    end

    it 'calls delete with correct URI' do
      client.delete_task(test_task)
      expect(client).to have_received(:delete).with("#{Boxr::Client::TASKS_URI}/task123")
    end
  end

  describe '#task_assignments' do
    before do
      allow(client).to receive(:get).and_return([mock_assignments_response, mock_response])
    end

    it 'retrieves task assignments' do
      result = client.task_assignments(test_task)
      expect(result).to eq([test_task_assignment, test_task_assignment])
    end

    it 'calls get with correct URI' do
      client.task_assignments(test_task)
      expect(client).to have_received(:get).with("#{Boxr::Client::TASKS_URI}/task123/assignments")
    end

    it 'accepts task as string ID' do
      result = client.task_assignments('task123')
      expect(result).to eq([test_task_assignment, test_task_assignment])
    end
  end

  describe '#create_task_assignment' do
    before do
      allow(client).to receive(:post).and_return(test_task_assignment)
    end

    it 'creates task assignment with assign_to' do
      result = client.create_task_assignment(test_task, assign_to: test_user)
      expect(result).to eq(test_task_assignment)
    end

    it 'creates task assignment with assign_to_login' do
      result = client.create_task_assignment(test_task, assign_to_login: 'user@example.com')
      expect(result).to eq(test_task_assignment)
    end

    it 'creates task assignment with both assign_to and assign_to_login' do
      result = client.create_task_assignment(test_task, assign_to: test_user, assign_to_login: 'user@example.com')
      expect(result).to eq(test_task_assignment)
    end

    it 'calls post with correct attributes for assign_to' do
      client.create_task_assignment(test_task, assign_to: test_user)
      expect(client).to have_received(:post).with(
        Boxr::Client::TASK_ASSIGNMENTS_URI,
        hash_including(
          task: { type: :task, id: 'task123' },
          assign_to: { id: 'user123' }
        )
      )
    end

    it 'calls post with correct attributes for assign_to_login' do
      client.create_task_assignment(test_task, assign_to_login: 'user@example.com')
      expect(client).to have_received(:post).with(
        Boxr::Client::TASK_ASSIGNMENTS_URI,
        hash_including(
          task: { type: :task, id: 'task123' },
          assign_to: { login: 'user@example.com' }
        )
      )
    end

    it 'accepts task as string ID' do
      result = client.create_task_assignment('task123', assign_to: test_user)
      expect(result).to eq(test_task_assignment)
    end

    it 'handles both assign_to and assign_to_login' do
      client.create_task_assignment(test_task, assign_to: test_user, assign_to_login: 'user@example.com')
      expect(client).to have_received(:post).with(
        Boxr::Client::TASK_ASSIGNMENTS_URI,
        hash_including(
          task: { type: :task, id: 'task123' },
          assign_to: { id: 'user123', login: 'user@example.com' }
        )
      )
    end
  end

  describe '#task_assignment' do
    before do
      allow(client).to receive(:get).and_return(test_task_assignment)
    end

    it 'retrieves task assignment by ID' do
      result = client.task_assignment('assignment123')
      expect(result).to eq(test_task_assignment)
    end

    it 'calls get with correct URI' do
      client.task_assignment('assignment123')
      expect(client).to have_received(:get).with("#{Boxr::Client::TASK_ASSIGNMENTS_URI}/assignment123")
    end

    it 'accepts task assignment as object' do
      result = client.task_assignment(test_task_assignment)
      expect(result).to eq(test_task_assignment)
    end
  end

  describe '#delete_task_assignment' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'deletes task assignment by object' do
      result = client.delete_task_assignment(test_task_assignment)
      expect(result).to eq({})
    end

    it 'deletes task assignment by ID' do
      result = client.delete_task_assignment('assignment123')
      expect(result).to eq({})
    end

    it 'calls delete with correct URI' do
      client.delete_task_assignment(test_task_assignment)
      expect(client).to have_received(:delete).with("#{Boxr::Client::TASK_ASSIGNMENTS_URI}/assignment123")
    end
  end

  describe '#update_task_assignment' do
    before do
      allow(client).to receive(:put).and_return(test_task_assignment)
    end

    it 'updates task assignment with message' do
      result = client.update_task_assignment(test_task_assignment, message: 'Updated message')
      expect(result).to eq(test_task_assignment)
    end

    it 'updates task assignment with resolution_state' do
      result = client.update_task_assignment(test_task_assignment, resolution_state: :completed)
      expect(result).to eq(test_task_assignment)
    end

    it 'updates task assignment with both parameters' do
      result = client.update_task_assignment(test_task_assignment, message: 'Done', resolution_state: :completed)
      expect(result).to eq(test_task_assignment)
    end

    it 'calls put with correct URI and attributes' do
      client.update_task_assignment(test_task_assignment, message: 'test', resolution_state: :completed)
      expect(client).to have_received(:put).with(
        "#{Boxr::Client::TASK_ASSIGNMENTS_URI}/assignment123",
        hash_including(message: 'test', resolution_state: :completed)
      )
    end

    it 'accepts task assignment as string ID' do
      result = client.update_task_assignment('assignment123', message: 'test')
      expect(result).to eq(test_task_assignment)
    end

    it 'omits nil parameters from attributes' do
      client.update_task_assignment(test_task_assignment, message: 'test')
      expect(client).to have_received(:put).with(
        anything,
        hash_including(message: 'test')
      )
    end
  end

  describe 'error handling' do
    let(:error_response) { instance_double(HTTP::Message, status: 404, header: {}) }

    before do
      allow(client).to receive(:get).and_raise(Boxr::BoxrError.new(status: 404, body: 'Not found'))
    end

    it 'raises BoxrError for invalid task ID' do
      expect do
        client.task_from_id('invalid_task')
      end.to raise_error(Boxr::BoxrError)
    end

    it 'raises BoxrError for invalid task assignment ID' do
      expect do
        client.task_assignment('invalid_assignment')
      end.to raise_error(Boxr::BoxrError)
    end
  end
end
