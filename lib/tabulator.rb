# frozen_string_literal: true

# Simple data tabulation
class Tabulator
  def initialize(**fmt)
    @format = fmt
  end

  def tabulate(...)
    t = [heading] + table(...)
    row_format = justified_format(t)

    t.each do |row|
      puts format(row_format, *row)
    end.count
  end

  def heading
    @format.keys.map(&:to_s).map(&:capitalize)
  end

  def table(data)
    data.map do |el|
      row = block_given? ? yield(el) : el
      @format.map { |col, f| format(f, row[col]) }
    end
  end

  def justified_format(table)
    table.transpose.map do |col|
      "%#{col.map(&:length).max}s"
    end.join(' ')
  end
end
