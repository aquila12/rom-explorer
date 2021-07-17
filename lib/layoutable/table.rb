# frozen_string_literal: true

require 'stringio'

module Layoutable
  # Implementation of a table container with fixed-size records
  class Table < Hash
    def initialize(data, stride, *rowinfo)
      super()
      self.default_proc = method(:loader)

      @data = data
      @stride = stride
      @rowclass = rowinfo.first.is_a?(Class) ? @rowclass = rowinfo.shift : Struct
      @rowargs = rowinfo
    end

    def record(index)
      @data.byteslice(index * @stride, @stride)
    end

    def format(record)
      @rowclass.new(record, *@rowargs)
    end

    def loader(tbl, index)
      tbl[index] = format(record(index))
    end

    def load_all
      io = StringIO.new(@data, 'rb')
      loop.each_with_index do |_, index|
        r = io.read(@stride)
        break unless r

        self[index] = format(r)
      end
      self
    end

    # Make it iterate like an array
    alias each each_value
  end
end
