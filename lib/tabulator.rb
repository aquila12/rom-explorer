# frozen_string_literal: true

# Helper to tabulate data nicely
module Tabulator
  module_function

  def tabulate(...)
    table = make_table(...)
    row_format = justified_format(table)

    table.each do |row|
      puts format(row_format, *row)
    end.count
  end

  def make_table(data, **fmt)
    [fmt.keys.map(&:to_s).map(&:capitalize)] +
      data.map do |el|
        row = yield(el)
        fmt.map { |col, f| format(f, row[col]) }
      end
  end

  def justified_format(table)
    table.transpose.map do |col|
      "%#{col.map(&:length).max}s"
    end.join(' ')
  end
end
