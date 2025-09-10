require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_file) { Hashie::Mash.new(id: '12345') }
  let(:test_comment) { Hashie::Mash.new(id: '67890', message: 'test comment') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:mock_comments_response) do
    BoxrMash.new(
      entries: [test_comment, test_comment]
    )
  end

  describe '#file_comments' do
    before do
      allow(client).to receive(:get_all_with_pagination).and_return(mock_comments_response)
    end

    it 'retrieves file comments' do
      result = client.file_comments(test_file)
      expect(result).to eq(mock_comments_response)
    end

    it 'retrieves file comments with fields' do
      client.file_comments(test_file, fields: %i[message created_at])
      expect(client).to have_received(:get_all_with_pagination).with(
        anything, hash_including(query: anything)
      )
    end

    it 'accepts file as string ID' do
      result = client.file_comments('12345')
      expect(result).to eq(mock_comments_response)
    end
  end

  describe '#add_comment_to_file' do
    before do
      allow(client).to receive(:post).and_return(test_comment)
    end

    it 'adds comment with message' do
      result = client.add_comment_to_file(test_file, message: 'test message')
      expect(result).to eq(test_comment)
    end

    it 'adds comment with tagged_message' do
      result = client.add_comment_to_file(test_file, tagged_message: 'tagged message')
      expect(result).to eq(test_comment)
    end

    it 'adds comment with both message and tagged_message' do
      result = client.add_comment_to_file(test_file, message: 'test message',
                                                     tagged_message: 'tagged message')
      expect(result).to eq(test_comment)
    end

    it 'accepts file as string ID' do
      result = client.add_comment_to_file('12345', message: 'test message')
      expect(result).to eq(test_comment)
    end
  end

  describe '#reply_to_comment' do
    before do
      allow(client).to receive(:post).and_return(test_comment)
    end

    it 'replies with message' do
      result = client.reply_to_comment(test_comment, message: 'reply message')
      expect(result).to eq(test_comment)
    end

    it 'replies with tagged_message' do
      result = client.reply_to_comment(test_comment, tagged_message: 'tagged reply')
      expect(result).to eq(test_comment)
    end

    it 'replies with both message and tagged_message' do
      result = client.reply_to_comment(test_comment, message: 'reply message',
                                                     tagged_message: 'tagged reply')
      expect(result).to eq(test_comment)
    end

    it 'accepts comment as string ID' do
      result = client.reply_to_comment('67890', message: 'reply message')
      expect(result).to eq(test_comment)
    end
  end

  describe '#change_comment' do
    before do
      allow(client).to receive(:put).and_return(test_comment)
    end

    it 'changes comment message' do
      result = client.change_comment(test_comment, 'new message')
      expect(result).to eq(test_comment)
    end

    it 'accepts comment as string ID' do
      result = client.change_comment('67890', 'new message')
      expect(result).to eq(test_comment)
    end
  end

  describe '#comment_from_id' do
    before do
      allow(client).to receive(:get).and_return(test_comment)
    end

    it 'retrieves comment by ID' do
      result = client.comment_from_id('67890')
      expect(result).to eq(test_comment)
    end

    it 'retrieves comment with fields' do
      client.comment_from_id('67890', fields: %i[message created_at])
      expect(client).to have_received(:get).with(anything, hash_including(query: anything))
    end

    it 'accepts comment as object' do
      result = client.comment_from_id(test_comment)
      expect(result).to eq(test_comment)
    end
  end

  describe '#comment (alias)' do
    before do
      allow(client).to receive(:get).and_return(test_comment)
    end

    it 'calls comment_from_id' do
      result = client.comment('67890')
      expect(result).to eq(test_comment)
    end
  end

  describe '#delete_comment' do
    before do
      allow(client).to receive(:delete).and_return({})
    end

    it 'deletes comment by object' do
      result = client.delete_comment(test_comment)
      expect(result).to eq({})
    end

    it 'deletes comment by ID' do
      result = client.delete_comment('67890')
      expect(result).to eq({})
    end
  end

  describe 'private methods' do
    describe '#add_comment' do
      before do
        allow(client).to receive(:post).and_return(test_comment)
      end

      it 'adds comment to file' do
        result = client.send(:add_comment, :file, '12345', 'message', nil)
        expect(result).to eq(test_comment)
      end

      it 'adds comment to comment' do
        result = client.send(:add_comment, :comment, '67890', 'message', nil)
        expect(result).to eq(test_comment)
      end

      it 'adds comment with message only' do
        client.send(:add_comment, :file, '12345', 'message', nil)
        expect(client).to have_received(:post).with(anything, hash_including(message: 'message'))
      end

      it 'adds comment with tagged_message only' do
        client.send(:add_comment, :file, '12345', nil, 'tagged message')
        expect(client).to have_received(:post).with(anything,
                                                    hash_including(tagged_message: 'tagged message'))
      end

      it 'adds comment with both message and tagged_message' do
        client.send(:add_comment, :file, '12345', 'message', 'tagged message')
        expect(client).to have_received(:post).with(anything,
                                                    hash_including(message: 'message',
                                                                   tagged_message: 'tagged message'))
      end

      it 'omits message when nil' do
        client.send(:add_comment, :file, '12345', nil, 'tagged message')
        expect(client).to have_received(:post).with(anything, hash_not_including(:message))
      end

      it 'omits tagged_message when nil' do
        client.send(:add_comment, :file, '12345', 'message', nil)
        expect(client).to have_received(:post).with(anything, hash_not_including(:tagged_message))
      end
    end
  end
end
