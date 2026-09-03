# frozen_string_literal: true

require 'gex'
require 'layoutable'
require 'rop_iso_extractor'
require_relative '../romlayout'

# Rings of Power Graphics Extractor CLI
class GexCLI < Gex
  def initialize
    romfile = ARGV.shift
    warn 'No ROM specified' unless romfile
    @rom = RingsOfPower.apply_to(File.binread(romfile))

    super(rom: @rom)

    parse_options!
    @outname += "+#{@skip_cells}" if @skip_cells
  end

  def handle_option(param)
    case param
    when 'p' then extract_portrait(Integer(arg))
    when 'm' then extract_map(Integer(arg))
    when 't' then extract_tile(Integer(arg))
    when 'd' then extract_dumped_ram(arg)
    when 'M' then specify_mask_colour(arg)
    when 'c' then specify_colour_palette(Integer(arg))
    when 'g' then specify_grid_resource(Integer(arg))
    when 'i' then specify_image_pixels(Integer(arg))
    when 's' then @sprite_h = Integer(arg)
    when 'w' then @cells_wide = Integer(arg)
    when 'o' then @skip_cells = Integer(arg)
    when 'l' then @cell_count = Integer(arg)
    else
      warn "Error: Unknown parameter: -#{param}"
      exit 1
    end
  end

  attr_reader :outname
  attr_accessor :sprite_h, :cells_wide, :skip_cells, :cell_count

  def extract_portrait(id)
    @outname = "portrait-#{id}"
    file = lzss_load(:portrait_directory, :portrait_files, id)

    @sega_palette = file.values_at(*(0..15).to_a)
    @pattern_pixels = file[:pixels]
    @cells_wide = 6
  end

  def extract_map(id)
    @outname = "map-#{id}"
    specify_image_pixels(10)
    specify_colour_palette(10)

    small_maps = 77..229
    @cells_wide = small_maps.cover?(id) ? 11 : 32

    @pattern_grid = map_as_grid(lzss_load(:map_directory, :map_files, id))
  end

  def extract_tile(id)
    @outname = "tile-#{id}"
    specify_colour_palette(10)
    specify_mask_colour('ff00ff')

    start = @rom[:isotile_index][id]
    tile = ROPISOExtractor.new(@rom[:isotile_data][start])
    exit 1 if tile.pixels.empty?

    @px_wide = tile.width
    @px_high = tile.height
    @bmp_data = tile.pixels

    warn "Linear raster #{@px_wide} x #{@px_high}"
  end

  def extract_dumped_ram(filename)
    @outname = filename.sub(/\.[^.]*$/, '')
    @pattern_pixels = File.binread(filename)
  end

  def specify_mask_colour(hexcode)
    hexcode = hexcode[1..] if hexcode.start_with? '#'

    @mask_colour = [hexcode].pack('H*').bytes
  end

  def specify_colour_palette(id)
    @outname ||= "palette-#{id}"
    @palette_number = id
  end

  def specify_grid_resource(id)
    @outname ||= "grid-#{id}"
    data = lzss_load(:lzss_directory, :lzss_files, id).unpack('n*')
    @pattern_grid = data.map { |e| [e[0..10], e[11].nonzero?, e[12].nonzero?] }
  end

  def specify_image_pixels(id)
    @outname ||= "patterns-#{id}"
    @pattern_pixels = lzss_load(:lzss_directory, :lzss_files, id)
  end

  private

  def map_as_grid(map_data)
    lookup = @rom[:ingame_map_lookup].load_all

    map_data.map do |t|
      tile = t[0..8]
      version = t[12].zero? ? :normal : :mirror
      entry = lookup[tile][version]

      # Frob to avoid the sentinel data when attempting to render non-world maps
      next nil if entry.zero? unless tile < 4

      [entry[2..], entry[0].nonzero?, entry[1].nonzero? ]
    end
  end

  def parse_options!
    while param = ARGV.shift
      if param =~ /^-(\w)(.*)/
        param = $1
        ARGV.unshift $2 unless $2.empty?
      else
        warn "Error: unexpected parameter: #{param}"
        exit 1
      end

      handle_option(param)
    end
  end

  def arg
    ARGV.shift.tap do |a|
      next if a

      warn "Argument required"
      exit 1
    end
  end

  def lzss_load(directory, files, index)
    entry = @rom[directory][index]

    warn "#{directory}[#{index}] is type #{type} - this could go un-well!" unless entry[:type] == 1
    @rom[files][entry[:offset]]
  end
end
