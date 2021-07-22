# frozen_string_literal: true

require 'lzss_decompressor'
require 'stringio'
require 'delegate'

module Layoutable
  # Wrapper to return the contained structure
  class LZSSData < SimpleDelegator
    def initialize(data, *rowinfo)
      # NB: Duplicate code from Container#initialize
      rowclass = rowinfo.first.is_a?(String) ? Struct : rowinfo.shift
      rowargs = rowinfo
      io = StringIO.new(data)
      inner_data = LZSSDecompressor.decompress(io)
      @compressed_size = io.pos
      @ratio = inner_data.size.to_f / @compressed_size

      super(rowclass.new(inner_data, *rowargs))
    end

    attr_reader :compressed_size, :ratio
  end
end
