# frozen_string_literal: true

require 'stringio'

module Layoutable
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

    def format_record(r)
      @rowclass.new(r, *@rowargs)
    end

    def loader(tbl, index)
      tbl[index] = format_record(record(index))
    end

    def load_all
      io = StringIO.new(@data, 'rb')
      loop.each_with_index do |_, index|
        r = io.read(@stride)
        break unless r
        self[index] = format_record(r)
      end
      self
    end
  end
end
