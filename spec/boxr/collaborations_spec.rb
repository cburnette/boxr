require 'spec_helper'

#rake spec SPEC_OPTS="-e \"invokes collaborations operations"\"
describe 'collaborations operations' do
  it "invokes collaborations operations" do
    puts "add collaboration"
    collaboration = BOX_CLIENT.add_collaboration(@test_folder, {id: @test_user.id, type: :user}, :viewer_uploader)
    expect(collaboration.accessible_by.id).to eq(@test_user.id)
    COLLABORATION = collaboration

    puts "inspect collaboration"
    collaboration = BOX_CLIENT.collaboration(COLLABORATION)
    expect(collaboration.id).to eq(COLLABORATION.id)

    puts "edit collaboration"
    collaboration = BOX_CLIENT.edit_collaboration(COLLABORATION, role: "viewer uploader")
    expect(collaboration.role).to eq("viewer uploader")

    puts "inspect folder collaborations"
    collaborations = BOX_CLIENT.folder_collaborations(@test_folder)
    expect(collaborations.count).to eq(1)
    expect(collaborations[0].id).to eq(COLLABORATION.id)

    puts "remove collaboration"
    result = BOX_CLIENT.remove_collaboration(COLLABORATION)
    expect(result).to eq({})
    collaborations = BOX_CLIENT.folder_collaborations(@test_folder)
    expect(collaborations.count).to eq(0)

    puts "inspect pending collaborations"
    pending_collaborations = BOX_CLIENT.pending_collaborations
    expect(pending_collaborations).to eq([])

    puts "add invalid collaboration"
    expect { BOX_CLIENT.add_collaboration(@test_folder, {id: @test_user.id, type: :user}, :invalid_role)}.to raise_error
  end
end
