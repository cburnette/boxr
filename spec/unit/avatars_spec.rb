# frozen_string_literal: true

require 'spec_helper'

describe Boxr::Client do
  let(:client) { described_class.new }
  let(:test_user) { Hashie::Mash.new(id: '12345', name: 'Test User', type: 'user') }
  let(:mock_response) { instance_double(HTTP::Message, status: 200, header: {}) }
  let(:avatar_data) { 'binary_avatar_data' }
  let(:mock_avatar_response) do
    BoxrMash.new(
      pic_urls: {
        small: 'https://example.com/avatar_small.png',
        large: 'https://example.com/avatar_large.png',
        preview: 'https://example.com/avatar_preview.png'
      }
    )
  end

  describe '#get_user_avatar' do
    before do
      allow(client).to receive(:get).and_return([avatar_data, mock_response])
    end

    it 'retrieves user avatar by ID' do
      result = client.get_user_avatar('12345')
      expect(result).to eq(avatar_data)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::USERS_URI}/12345/avatar",
        process_response: false
      )
    end

    it 'handles user object' do
      result = client.get_user_avatar(test_user)
      expect(result).to eq(avatar_data)
      expect(client).to have_received(:get).with(
        "#{Boxr::Client::USERS_URI}/12345/avatar",
        process_response: false
      )
    end
  end

  describe '#create_user_avatar' do
    let(:pic_file) { double('file', path: '/path/to/avatar.png') }

    before do
      allow(client).to receive(:post).and_return([mock_avatar_response, mock_response])
    end

    it 'creates user avatar with all optional parameters' do
      result = client.create_user_avatar(
        '12345',
        pic_file,
        pic_file_name: 'avatar.png',
        pic_content_type: 'image/png'
      )
      expect(result).to eq(mock_avatar_response)
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::USERS_URI}/12345/avatar",
        {
          pic: pic_file,
          pic_file_name: 'avatar.png',
          pic_content_type: 'image/png'
        },
        process_body: false,
        content_type: 'multipart/form-data'
      )
    end

    it 'handles user object' do
      result = client.create_user_avatar(test_user, pic_file)
      expect(result).to eq(mock_avatar_response)
      expect(client).to have_received(:post).with(
        "#{Boxr::Client::USERS_URI}/12345/avatar",
        { pic: pic_file },
        process_body: false,
        content_type: 'multipart/form-data'
      )
    end
  end

  describe '#delete_user_avatar' do
    before do
      allow(client).to receive(:delete).and_return([{}, mock_response])
    end

    it 'deletes user avatar by ID' do
      result = client.delete_user_avatar('12345')
      expect(result).to eq({})
      expect(client).to have_received(:delete).with("#{Boxr::Client::USERS_URI}/12345/avatar")
    end

    it 'handles user object' do
      result = client.delete_user_avatar(test_user)
      expect(result).to eq({})
      expect(client).to have_received(:delete).with("#{Boxr::Client::USERS_URI}/12345/avatar")
    end
  end
end
