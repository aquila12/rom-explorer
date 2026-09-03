# frozen_string_literal: true

# Rings of Power Graphics Extractor (base class)
class Gex
  def initialize(rom:)
    @rom = rom
  end

  def histogram
    @histogram ||= bmp_data.unpack1('H*').chars.tally.transform_keys { |k| k.to_i(16) }
  end

  def rgba_palette
    @palette ||= palette_from_sega
    @palette[0] = @mask_colour if @mask_colour

    @palette
  end

  def sega_palette
    @sega_palette ||= @rom[:palettes][@palette_number || 0]
  end

  def bmp_data
    @bmp_data ||= _bmp_data
  end

  def dimensions
    bmp_data
    [@px_wide || @cells_wide * 8, @px_high || @cells_high * 8]
  end

  def cell_dimensions
    bmp_data
    return unless @cells_high

    [@cells_wide, @cells_high]
  end

  attr_reader :pattern_grid

  private

  def palette_from_sega
    sega_palette.map do |c|
      rgba = [c[0..3], c[4..7], c[8..11], c[12..15]]
      rgba.map { |ch| ch * 0x12 }
    end
  end

  def calibrate_grid!
    @pattern_grid ||= generate_grid

    # Default to making a squareish dump image
    @total_cells ||= @pattern_grid.length
    @cells_wide ||= (@total_cells ** 0.5).floor

    d, m = @total_cells.divmod(@cells_wide)
    @cells_high = m.zero? ? d : d + 1
    @pattern_grid += [nil] * m if @pattern_grid
  end

  def _bmp_data
    unless @pattern_pixels || @pattern_grid
      @pattern_pixels = 16.times.flat_map { |n| [n * 0x11111111] * 8 }.pack('V*')
    end

    @pattern_pixels = @pattern_pixels[32 * @skip_cells..] if @skip_cells
    @pattern_pixels = @pattern_pixels[...32 * @cell_count] if @cell_count

    calibrate_grid!
    restripe_data
  end

  def restripe_data
    cells = @pattern_grid.each_slice(@cells_wide).to_a
    lines = @pattern_pixels.unpack('V*')
    patterns = lines.each_slice(8).to_a
    reverses = lines.map { |p| format('%08x', p).reverse.to_i(16) }.each_slice(8).to_a

    (8 * @cells_high).times.flat_map do |y|
      row, line = y.divmod(8)
      Array.new(@cells_wide) do |col|
        p, hf, vf = cells[row][col]
        next 0 unless p

        pat = hf ? reverses[p] : patterns[p]
        l = vf ? 7 - line : line

        pat ? pat[l] : 0
      end
    end.pack('V*')
  end

  def generate_grid
    @sprite_h ||= 1
    @total_cells = @pattern_pixels.length / 32
    return Array.new(@total_cells, &:itself) if @sprite_h == 1

    section = @cells_wide * @sprite_h
    Array.new(@total_cells) do |n|
      s, q = n.divmod(section)
      r, c = q.divmod(@cells_wide)

      s * section + c * @sprite_h + r
    end
  end
end
