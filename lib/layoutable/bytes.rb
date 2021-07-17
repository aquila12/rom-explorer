# frozen_string_literal: true

module Layoutable
  # Container allowing byte-indexed retrieval of elements
  # NB: Index can be a range
  class Bytes < Hash
    def initialize(data, *rowinfo)
      super()
      self.default_proc = method(:loader)

      @data = data
      @rowclass = rowinfo.first.is_a?(Class) ? @rowclass = rowinfo.shift : Struct
      @rowargs = rowinfo
    end

    def format(record)
      @rowclass.new(record, *@rowargs)
    end

    def loader(tbl, index)
      tbl[index] = format(@data[index])
    end
  end
end
