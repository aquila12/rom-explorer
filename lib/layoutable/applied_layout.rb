# frozen_string_literal: true

module Layoutable
  class AppliedLayout < Hash
    def initialize(data, directory)
      super()
      self.default_proc = method(:loader)
      @target = data
      @directory = directory
    end

    attr_reader :directory

    def loader(dir, label)
      entry = @directory.fetch(label)
      range = entry[:range]
      data = @target[range]
      dir[label] = entry[:class].new(data, *entry[:args])
    end

    def load_all
      @directory.keys.each { |k| self[k] }
      self
    end
  end
end
