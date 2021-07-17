# frozen_string_literal: true

module Layoutable
  class Layout
    def initialize
      @size = 0
      @structure = {}
      @layout = {}

      structure :bytes, String
    end

    def structure(name, type, *args)
      @structure[name] = resolve_type(type, *args)
    end

    def resolve_type(type, *args)
      type.is_a?(Class) ? [type, *args] : @structure.fetch(type)
    end

    def check_offset!(offset)
      return if offset < @size

      raise ArgumentError, format('Offset %x exceeds size %x', offset, @size)
    end

    def at(offset, label, type, *args)
      check_offset! offset

      type, *args = resolve_type(type, *args)
      @layout[offset] = [ label, { class: type, args: args } ]
    end

    def size(size)
      @size = size
    end

    def generate_directory
      @layout[@size] = nil
      @directory = {}
      @layout.sort.each_cons(2) do |(offset, (label, info)), (next_offset)|
        info[:range] = offset...next_offset
        label = format(label, offset).to_sym if label.is_a? String
        @directory[label] = info
      end
      @directory
    end

    def directory
      @directory ||= generate_directory
    end
  end
end
