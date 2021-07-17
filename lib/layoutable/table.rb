# frozen_string_literal: true

require 'stringio'

module Layoutable
  class Table
    include Enumerable

    def initialize(data, stride, *rowinfo)
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

    def [](index)
      format_record(record(index))
    end

    def each
      io = StringIO.new(@data, 'rb')
      loop do
        r = io.read(@stride)
        break unless r
        yield format_record(r)
      end
    end
  end
end
