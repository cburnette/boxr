# frozen_string_literal: true

class BoxrMash < Hashie::Mash

  self.disable_warnings

  def entries
    self["entries"]
  end

  def size
    self["size"]
  end
end
