# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoxrCollection, :skip_reset do
  subject(:collection) { described_class.new(items, offset, limit, total_count) }

  let(:item_struct) { Struct.new(:type) }

  let(:items) { %w[file folder web_link file folder].map { |type| item_struct.new(type) } }
  let(:offset) { 0 }
  let(:limit) { 3 }
  let(:total_count) { 5 }

  describe '#files' do
    subject { collection.files }

    it { is_expected.to contain_exactly(*(items.select {|i| i.type == 'file'})) }
  end

  describe '#folders' do
    subject { collection.folders }

    it { is_expected.to contain_exactly(*(items.select {|i| i.type == 'folder'})) }
  end

  describe '#web_links' do
    subject { collection.web_links }

    it { is_expected.to contain_exactly(*(items.select {|i| i.type == 'web_link'})) }
  end

  describe '#offset' do
    subject { collection.offset }

    it { is_expected.to eq(offset) }
  end

  describe '#limit' do
    subject { collection.limit }

    it { is_expected.to eq(limit) }
  end

  describe '#total_count' do
    subject { collection.total_count }

    it { is_expected.to eq(total_count) }
  end
end
