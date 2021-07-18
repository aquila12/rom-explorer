# frozen_string_literal: true

require 'lzss_decompressor'
require 'stringio'

module Layoutable
  # Wrapper to return the contained structure
  module LZSSData
    module_function

    def new(data, *rowinfo)
      # NB: Duplicate code from Container#initialize
      rowclass = rowinfo.first.is_a?(String) ? Struct : rowinfo.shift
      rowargs = rowinfo

      inner_data = LZSSDecompressor.decompress(StringIO.new(data))

      rowclass.new(inner_data, *rowargs)
    end
  end
end
