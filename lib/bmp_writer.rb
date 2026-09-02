# frozen_string_literal: true

require 'stringio'

# Writer for 16-colour 4bpp bitmaps
class BMPWriter
  def initialize(filename)
    @filename = filename
  end

  def write(width, height, palette, data)
    @f = File.open(@filename, 'wb')
    write_header(width, height)
    write_palette(palette)
    @pdata = @f.pos
    write_pixel_data(data, width)
    @size = @f.pos
    write_offsets
  ensure
    @f.close
  end

  private

  def write_header(width, height)
    @f.write 'BM'
    @size_pos = @f.pos
    @f.write [0, 0, 0].pack('Vvv')
    @pdata_pos = @f.pos
    @f.write [0, 40, width, -height].pack('V*')
    @f.write [1, 4, 0, 0, 0, 0, 0, 0].pack('vvV*')
  end

  def write_palette(rgba_palette)
    bgra_palette = Array.new(16) do |index|
      r, g, b, a = rgba_palette[index]
      [b, g, r, a].map { |x| x || 0 }
    end

    @f.write(bgra_palette.flatten.pack('C*'))
  end

  def write_pixel_data(data, width)
    return @f.write(data) if width % 8 == 0

    io = StringIO.new(data)
    data_bytes = width / 2
    padding = "\0" * (4 - data_bytes % 4)

    while(line = io.read(data_bytes)) do
      @f.write(line + padding)
    end
  end

  def write_offsets
    @f.seek(@size_pos)
    @f.write [@size].pack('V*')
    @f.seek(@pdata_pos)
    @f.write [@pdata].pack('V*')
  end
end
