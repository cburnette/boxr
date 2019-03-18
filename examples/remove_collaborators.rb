# frozen_string_literal: true

require 'dotenv'; Dotenv.load('../.env')
require 'awesome_print'
require 'boxr'

box_client = Boxr::Client.new(ENV['BOX_DEVELOPER_TOKEN'])

current_user_id = box_client.me.id

folders = box_client.root_folder_items(fields: %i[owned_by name]).folders
owned_folders = folders.select { |f| f.owned_by.id == current_user_id }

removed_count = 0
owned_folders.each do |f|
  puts "Checking folder '#{f.name}'"
  collabs = box_client.folder_collaborations(f, fields: [:accessible_by])
  collabs.each do |c|
    box_client.remove_collaboration(c)
    removed_count += 1
    puts "\t removed collaboration with the #{c.accessible_by.type} #{c.accessible_by.name}"
  end
end

puts
puts "Removed #{removed_count} collaborations from #{owned_folders.count} folders"
