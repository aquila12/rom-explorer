# frozen_string_literal: true

# Simple data tabulation
class Tabulator
  def initialize(**fmt)
    @format = fmt
    @align = Hash.new(1)
  end

  def align(side, *fields)
    alignment = side == :left ? -1 : 1
    fields.each { |f| @align[f] = alignment }
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
    alignments = @format.keys.map { |k| @align[k] }
    table.transpose.each_with_index.map do |col, index|
      "%#{col.map(&:length).max * alignments[index]}s"
    end.join(' ')
  end
end
