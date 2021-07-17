# frozen_string_literal: true

module Layoutable
  # Top-level container for laid-out binaries
  class AppliedLayout < Hash
    def initialize(data, directory)
      super()
      self.default_proc = method(:loader)

      @data = data
      @directory = directory
    end

    attr_reader :directory

    def loader(dir, label)
      entry = @directory.fetch(label)
      range = entry[:range]
      data = @data[range]
      dir[label] = entry[:class].new(data, *entry[:args])
    end

    def load_all
      @directory.each_key { |k| self[k] }
      self
    end
  end
end
