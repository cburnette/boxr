# rake spec SPEC_OPTS="-e \"invokes collection operations"\"
require 'spec_helper'

describe 'collection operations' do
  it 'invokes collection operations' do
    puts 'list all collections'
    collections = BOX_CLIENT.collections
    expect(collections).not_to be_nil
    expect(collections.entries).not_to be_empty

    puts 'find favorites collection'
    favorites = collections.entries.find { |c| c.collection_type == 'favorites' }
    expect(favorites).not_to be_nil
    expect(favorites.name).to eq('Favorites')

    puts 'get collection by id'
    collection = BOX_CLIENT.collection_from_id(favorites.id)
    expect(collection.id).to eq(favorites.id)
    expect(collection.collection_type).to eq('favorites')

    puts 'get collection using alias'
    collection = BOX_CLIENT.collection(favorites.id)
    expect(collection.id).to eq(favorites.id)
  end
end
