# frozen_string_literal: true

module Layoutable
  # Container allowing byte-indexed retrieval of elements
  # NB: Index can be a range
  class Bytes < Container
    def record(index)
      index.is_a?(Numeric) ? @data[index..] : @data[index]
    end
  end
end
