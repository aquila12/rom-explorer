# frozen_string_literal: true

# Rings of Power isometric graphic extractor
class ROPISOExtractor
  def initialize(data)
    @in = data
    return if extract!

    warn "No data"
    @width = @height = 0
    @pixels = ''
  end

  attr_reader :width, :height, :pixels

  private

  def extract!
    io = StringIO.new(@in)
    lines = []

    while((b = io.read(1).bytes.first).nonzero?) do
      offset = b[0..3]
      len = b[4..7]

      lines << padding(offset) + io.read(len)
    end

    return if lines.empty?

    bytewidth = lines.map(&:length).max
    @width = 2 * bytewidth
    @height = lines.length

    @pixels = lines.map { |l| l + padding(bytewidth - l.length) }.join
  end

  def padding(n)
    "\0" * n
  end
end
