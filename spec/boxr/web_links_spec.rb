#rake spec SPEC_OPTS="-e \"invokes web links operations"\"
describe "web links operations" do
  it 'invokes web links operations' do
    puts "create web link"
    web_link = BOX_CLIENT.create_web_link(TEST_WEB_URL, '0', name: "my new link", description: "link description...")
    expect(web_link.url).to eq(TEST_WEB_URL)

    puts "get web link"
    web_link_new = BOX_CLIENT.get_web_link(web_link)
    expect(web_link_new.id).to eq(web_link.id)

    puts "update web link"
    updated_web_link = BOX_CLIENT.update_web_link(web_link, name: 'new name', description: 'new description', url: TEST_WEB_URL2)
    expect(updated_web_link.url).to eq(TEST_WEB_URL2)

    puts "delete web link"
    result = BOX_CLIENT.delete_web_link(web_link)
    expect(result).to eq({})

    puts "get trashed web link"
    trashed_web_link = BOX_CLIENT.trashed_web_link(web_link)
    expect(trashed_web_link.item_status).to eq("trashed")

    puts "restore trashed web link"
    restored_web_link = BOX_CLIENT.restore_trashed_web_link(web_link)
    expect(restored_web_link.item_status).to eq("active")

    puts "trash and permanently delete web link"
    BOX_CLIENT.delete_web_link(web_link)
    result = BOX_CLIENT.delete_trashed_web_link(web_link)
    expect(result).to eq({})
  end
end
