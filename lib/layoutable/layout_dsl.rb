# frozen_string_literal: true

module Layoutable
  # Implementation of the layout DSL
  class LayoutDSL
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

    def at(offset, label, type, *args, note: nil)
      check_offset! offset

      @layout[offset] = [label, resolve_type(type, *args), note]
    end

    def size(size)
      @size = size
    end

    def build
      @layout[@size] = nil
      Layout.new.tap do |l|
        @layout.sort.each_cons(2) do |(offset, (label, info, note)), (next_offset)|
          label = format(label, offset).to_sym if label.is_a? String
          l.append(label, info, offset, next_offset, note)
        end
      end
    end
  end
end
