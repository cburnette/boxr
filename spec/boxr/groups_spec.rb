require 'spec_helper'

#rake spec SPEC_OPTS="-e \"invokes group operations"\"
describe 'group operations' do
  it "invokes group operations" do
    puts "create group"
    group = BOX_CLIENT.create_group(TEST_GROUP_NAME)
    expect(group.name).to eq(TEST_GROUP_NAME)

    puts "inspect groups"
    groups = BOX_CLIENT.groups
    test_group = groups.find{|g| g.name == TEST_GROUP_NAME}
    expect(test_group).to_not be_nil

    puts "get group info"
    group_info = BOX_CLIENT.group(test_group)
    expect(group_info.id).to eq(test_group.id)

    puts "update group"
    new_name = "Test Boxr Group Renamed"
    group = BOX_CLIENT.update_group(test_group, new_name)
    expect(group.name).to eq(new_name)
    group = BOX_CLIENT.rename_group(test_group,TEST_GROUP_NAME)
    expect(group.name).to eq(TEST_GROUP_NAME)

    puts "add user to group"
    group_membership = BOX_CLIENT.add_user_to_group(@test_user, test_group)
    expect(group_membership.user.id).to eq(@test_user.id)
    expect(group_membership.group.id).to eq(test_group.id)
    membership = group_membership

    puts "inspect group membership"
    group_membership = BOX_CLIENT.group_membership(membership)
    expect(group_membership.id).to eq(membership.id)

    puts "inspect group memberships"
    group_memberships = BOX_CLIENT.group_memberships(test_group)
    expect(group_memberships.count).to eq(1)
    expect(group_memberships.first.id).to eq(membership.id)

    puts "inspect group memberships for a user"
    group_memberships = BOX_CLIENT.group_memberships_for_user(@test_user)
    expect(group_memberships.count).to eq(1)
    expect(group_memberships.first.id).to eq(membership.id)

    puts "inspect group memberships for me"
    #this is whatever user your developer token is tied to
    group_memberships = BOX_CLIENT.group_memberships_for_me
    expect(group_memberships).to be_a(Array)

    puts "update group membership"
    group_membership = BOX_CLIENT.update_group_membership(membership, :admin)
    expect(group_membership.role).to eq("admin")

    puts "delete group membership"
    result = BOX_CLIENT.delete_group_membership(membership)
    expect(result).to eq({})
    group_memberships = BOX_CLIENT.group_memberships_for_user(@test_user)
    expect(group_memberships.count).to eq(0)

    puts "inspect group collaborations"
    group_collaboration = BOX_CLIENT.add_collaboration(@test_folder, {id: test_group.id, type: :group}, :editor)
    expect(group_collaboration.accessible_by.id).to eq(test_group.id)

    puts "delete group"
    response = BOX_CLIENT.delete_group(test_group)
    expect(response).to eq({})
  end
end
