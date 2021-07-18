# frozen_string_literal: true

require 'tabulator'

module Layoutable
  # Representation of a built layout
  class Layout < Hash
    def append(label, info, offset, next_offset, note)
      range = offset...next_offset
      self[label] = info.merge(range: range, note: note)
    end

    def listing
      table = Tabulator.new(start: addr_fmt, end: addr_fmt, length: '%d', label: '%s', note: '%s')

      table.tabulate(self) do |label, info|
        r = info[:range]
        r_end = r.reverse_each.first
        info.merge(start: r.first, end: r_end, length: r.count, label: label)
      end
    end

    private

    def addr_fmt
      @addr_fmt ||= format(
        '0x%%0%dx',
        values
          .map { |i| i[:range].reverse_each.first }
          .max.to_s(16).length
      )
    end
  end
end
