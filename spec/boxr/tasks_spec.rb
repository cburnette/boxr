require 'spec_helper'

#rake spec SPEC_OPTS="-e \"invokes task operations"\"
describe 'task operations' do
  it "invokes task operations" do
    test_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder)
    collaboration = BOX_CLIENT.add_collaboration(@test_folder, {id: @test_user.id, type: :user}, :editor)

    puts "create task"
    new_task = BOX_CLIENT.create_task(test_file, message: TEST_TASK_MESSAGE)
    expect(new_task.message).to eq(TEST_TASK_MESSAGE)
    TEST_TASK = new_task

    puts "inspect file tasks"
    tasks = BOX_CLIENT.file_tasks(test_file)
    expect(tasks.first.id).to eq(TEST_TASK.id)

    puts "inspect task"
    task = BOX_CLIENT.task(TEST_TASK)
    expect(task.id).to eq(TEST_TASK.id)

    puts "update task"
    NEW_TASK_MESSAGE = "new task message"
    updated_task = BOX_CLIENT.update_task(TEST_TASK, message: NEW_TASK_MESSAGE)
    expect(updated_task.message).to eq(NEW_TASK_MESSAGE)

    puts "create task assignment"
    task_assignment = BOX_CLIENT.create_task_assignment(TEST_TASK, assign_to: @test_user.id)
    expect(task_assignment.assigned_to.id).to eq(@test_user.id)
    TASK_ASSIGNMENT = task_assignment

    puts "inspect task assignment"
    task_assignment = BOX_CLIENT.task_assignment(TASK_ASSIGNMENT)
    expect(task_assignment.id).to eq(TASK_ASSIGNMENT.id)

    puts "inspect task assignments"
    task_assignments = BOX_CLIENT.task_assignments(TEST_TASK)
    expect(task_assignments.count).to eq(1)
    expect(task_assignments[0].id).to eq(TASK_ASSIGNMENT.id)

    #TODO: can't do this test yet because the test user needs to confirm their email address before you can do this
    puts "update task assignment"
    expect {
              box_client_as_test_user = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'], as_user_id: @test_user.id)
              new_message = "Updated task message"
              task_assignment = box_client_as_test_user.update_task_assignment(TEST_TASK, resolution_state: :completed)
              expect(task_assignment.resolution_state).to eq('completed')
            }.to raise_error

    puts "delete task assignment"
    result = BOX_CLIENT.delete_task_assignment(TASK_ASSIGNMENT)
    expect(result).to eq({})

    puts "delete task"
    result = BOX_CLIENT.delete_task(TEST_TASK)
    expect(result).to eq({})
  end
end
