# frozen_string_literal: true

require 'stringio'

module Layoutable
  # Implementation of a table container with fixed-size records
  class Table < Container
    def initialize(data, stride, *rowinfo)
      @stride = stride
      super(data, *rowinfo)
    end

    def record(index)
      @data.byteslice(index * @stride, @stride)
    end

    # This feels wrong here, but it didn't fall out in refactor
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
