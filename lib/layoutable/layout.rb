# frozen_string_literal: true

module Layoutable
  # Representation of a built layout
  class Layout < Hash
    def append(label, info, offset, next_offset)
      self[label] = info.merge(
        range: offset...next_offset,
        length: next_offset - offset
      )
    end
  end
end
