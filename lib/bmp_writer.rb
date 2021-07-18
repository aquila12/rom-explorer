# frozen_string_literal: true

# Writer for 16-colour 4bpp bitmaps
class BMPWriter
  def initialize(filename)
    @filename = filename
  end

  def write(width, height, palette, data)
    @f = File.open(@filename, 'wb')
    write_header(width, height)
    write_palette(palette)
    write_pixel_data(data)
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

  def write_palette(palette)
    @f.write(palette.flatten.pack('C*'))
  end

  def write_pixel_data(data)
    @pdata = @f.pos
    @f.write data
    @size = @f.pos
  end

  def write_offsets
    @f.seek(@size_pos)
    @f.write [@size].pack('V*')
    @f.seek(@pdata_pos)
    @f.write [@pdata].pack('V*')
  end
end
