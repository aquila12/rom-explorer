# frozen_string_literal: true

module Layoutable
  # Generic container
  class Container < Hash
    def initialize(data, *rowinfo)
      super()
      self.default_proc = method(:loader)

      @data = data
      @rowclass = rowinfo.first.is_a?(Class) ? @rowclass = rowinfo.shift : Struct
      @rowargs = rowinfo
    end

    attr_accessor :data

    def format(record)
      @rowclass.new(record, *@rowargs)
    end

    def loader(container, index)
      container[index] = format record(index)
    end
  end
end
