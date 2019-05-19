require 'spec_helper'

#rake spec SPEC_OPTS="-e \"invokes comment operations"\"
describe 'comment operations' do
  it "invokes comment operations" do
    new_file = BOX_CLIENT.upload_file("./spec/test_files/#{TEST_FILE_NAME}", @test_folder)
    test_file = new_file

    puts "add comment to file"
    comment = BOX_CLIENT.add_comment_to_file(test_file, message: COMMENT_MESSAGE)
    expect(comment.message).to eq(COMMENT_MESSAGE)
    COMMENT = comment

    puts "reply to comment"
    reply = BOX_CLIENT.reply_to_comment(COMMENT, message: REPLY_MESSAGE)
    expect(reply.message).to eq(REPLY_MESSAGE)

    puts "get file comments"
    comments = BOX_CLIENT.file_comments(test_file)
    expect(comments.count).to eq(2)

    puts "update a comment"
    comment = BOX_CLIENT.change_comment(COMMENT, CHANGED_COMMENT_MESSAGE)
    expect(comment.message).to eq(CHANGED_COMMENT_MESSAGE)

    puts "get comment info"
    comment = BOX_CLIENT.comment(COMMENT)
    expect(comment.id).to eq(COMMENT.id)

    puts "delete comment"
    result = BOX_CLIENT.delete_comment(COMMENT)
    expect(result).to eq({})
  end
end
