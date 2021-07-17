# frozen_string_literal: true

module Layoutable
  class Layout < Hash
    def initialize(&block)
      @layout = DSL.new
      @layout.instance_eval(&block)
      default_proc = method(:loader)
    end

    attr_reader :layout

    def apply_to(data)
      @target = data
      clear
    end

    def loader(dir, label)
      entry = @layout.directory.fetch(label)
      range = entry[:range]
      data = @target[range]
      dir[label] = entry[:class].new(data, *entry[:args], range: range)
    end
  end
end
