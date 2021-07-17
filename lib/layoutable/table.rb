# frozen_string_literal: true

module Layoutable
  class Table
    def initialize(data, stride, *rowinfo)
      @data = data
      @stride = stride
      @rowclass = rowinfo.first.is_a? Class ? @rowclass = rowinfo.shift : Struct
      @rowargs = rowinfo
    end

    def record(index)
      @data.byteslice(index * @stride, @stride)
    end

    def [](index)
      @rowclass.new(record(index), *@rowargs)
    end
  end
end
