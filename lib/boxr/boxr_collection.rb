# frozen_string_literal: true

class BoxrCollection < Array
  attr_reader :offset, :limit, :total_count

  def initialize(items, offset, limit, total_count)
    super(items)

    @offset = offset
    @limit = limit
    @total_count = total_count
  end

  def files
    collection_for_type('file')
  end

  def folders
    collection_for_type('folder')
  end

  def web_links
    collection_for_type('web_link')
  end

  private


  # NOTE: @offset, @limit, @total_count returns count of ALL TYPES of the items
  # it can have a bit confusing behavior, when for example
  # there is 20 itmes in the folder:
  # 7 files and 3 folders
  # #collection_for_type('file') returns only 7 file items when you're set limit to 10, offset to 0
  # there is no easy way to fix this
  # as total_count is received to the API, and there is no easy way to filter by types to have proper
  # without addition API queries and serious gem refactorings whis is doesn't worth doing that now
  def collection_for_type(type)
    items = select { |i| i.type == type }

    BoxrCollection.new(items, @offset, @limit, @total_count)
  end
end
