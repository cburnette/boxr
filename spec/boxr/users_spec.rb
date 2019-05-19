require 'spec_helper'

#rake spec SPEC_OPTS="-e \"invokes user operations"\"
describe 'user operations' do
  it "invokes user operations" do
    puts "inspect current user"
    user = BOX_CLIENT.current_user
    expect(user.status).to eq('active')
    user = BOX_CLIENT.me(fields: [:role])
    expect(user.role).to_not be_nil

    puts "inspect a user"
    user = BOX_CLIENT.user(@test_user)
    expect(user.id).to eq(@test_user.id)

    puts "inspect all users"
    all_users = BOX_CLIENT.all_users()
    test_user = all_users.find{|u| u.id == @test_user.id}
    expect(test_user).to_not be_nil

    #create user is tested in the before method

    puts "update user"
    new_name = "Chuck Nevitt"
    user = BOX_CLIENT.update_user(@test_user, name: new_name)
    expect(user.name).to eq(new_name)

    puts "move user's folder"
    second_test_user = BOX_CLIENT.create_user("Second Test User", login: "second_test_user@#{('a'..'z').to_a.shuffle[0,10].join}.com", role: 'coadmin')
    folder = BOX_CLIENT.move_users_folder(@test_user, Boxr::ROOT, second_test_user)
    expect(folder.owned_by.id).to eq(second_test_user.id)

    # TODO: Broken while waiting to figure out permissions
    # puts "add email alias for user"
    # email_alias = "test-boxr-user-alias@boxntest.com" #{('a'..'z').to_a.shuffle[0,10].join}.com"
    # new_alias = BOX_CLIENT.add_email_alias_for_user(@test_user, email_alias)
    # expect(new_alias.type).to eq('email_alias')

    # puts "get email aliases for user"
    # email_aliases = BOX_CLIENT.email_aliases_for_user(@test_user)
    # expect(email_aliases.first.id).to eq(new_alias.id)

    # puts "remove email alias for user"
    # result = BOX_CLIENT.remove_email_alias_for_user(@test_user, new_alias.id)
    # expect(result).to eq({})

    puts "delete users"
    BOX_CLIENT.delete_user(second_test_user, force: true)
    result = BOX_CLIENT.delete_user(@test_user, force: true)
    expect(result).to eq({})
  end
end
