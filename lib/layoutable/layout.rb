# frozen_string_literal: true

module Layoutable
  # Implementation of the layout DSL
  class Layout
    def initialize
      @size = 0
      @structure = {}
      @layout = {}

      structure :bytes, Bytes, 'a*'
    end

    def structure(name, type, *args)
      @structure[name] = resolve_type(type, *args)
    end

    def resolve_type(type, *args)
      return @structure.fetch(type) if type.is_a? Symbol

      { class: type, args: args }
    end

    def check_offset!(offset)
      return if offset < @size

      raise ArgumentError, format('Offset %<o>x exceeds size %<s>x', o: offset, s: @size)
    end

    def at(offset, label, type, *args)
      check_offset! offset

      @layout[offset] = [label, resolve_type(type, *args)]
    end

    def size(size)
      @size = size
    end

    def generate_directory
      @layout[@size] = nil
      @directory = {}
      @layout.sort.each_cons(2) do |(offset, (label, info)), (next_offset)|
        label = format(label, offset).to_sym if label.is_a? String
        @directory[label] = info.merge(range: offset...next_offset)
      end
      @directory
    end

    def directory
      @directory ||= generate_directory
    end
  end
end
