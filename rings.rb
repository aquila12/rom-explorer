require_relative 'dumb_dsl'

layout 'rings.bin' do
  m68k = bytes
  code = [:code, m68k]
  directory = array(struct('NNn', %i[offset length type]))

  at 0x00000, reset_state: struct('NN', %i[init_sp init_pc])
  at 0x00008, :data
  at 0x00100, rom_header: bytes
  at 0x00200, bootloader: m68k
  at 0x00290, :data

  at 0x002fa, *code
  at 0x0dd5c, decompress_lzss: m68k # Compression type 1, LZSS 4k sliding window
  at 0x0de1a, decompress_plain: m68k # Compression type 0, straight data
  at 0x0df58, :table, array(value_raw('N')) # Raw addresses into the ROM to the following section
  at 0x0e358, *code # Lots of unrolled loops and unconditional branch to e3e2 - maybe blitter?

  at 0x1107a, *code
  at 0x12072, void_found_you: m68k # May be an exception handler
  at 0x13654, archive_extract: m68k # Look up and decompress, f(void *buffer, int index, void *table, void *data)
  at 0x136fc, decompress_para: m68k # Compression type 5, n_bytes = f(int word_count, void *buffer, void *data)
  at 0x1383d, *code

  at 0x197b0, :data

  at 0x1a710, text_class_full: array(value_raw('Z12'))
  at 0x1a794, text_class_abbr: array(value_raw('Z4'))
  at 0x1a7c0, text_status_filler: array(value_raw('Z8'))
  at 0x1a7f0, text_status_health: array(value_raw('Z16'))
  at 0x1a8c0, text_status_mana: array(value_raw('Z16'))
  at 0x1a990, text_status_mood: array(value_raw('Z16'))
  at 0x1aa60, text_status_level: array(array_n(9, value_raw('Z10'))) # Untrained has no level vector
  at 0x1ade4, :data
  at 0x1ae98, ingame_map_lookup: array(struct('CC', %i[mirror normal])) # Indexes textures somehow
  at 0x1b298, city_goods: array(struct('CC', %i[export import])) # Half or double price
  at 0x1b2e0, gate_locations: array(struct('nn', %i[lon lat])) # Centres of the gates
  at 0x1b300, gate_deltas: array(struct('s>s>', %i[dlon dlat])) # Relative position of 8 squares around a centre
  at 0x1b320, text_title_scroller: array(value_raw('Z42'))
  at 0x1b446, :data
  at 0x1b4d2, parallax_table: array(struct('c*', [:x_offset]))
  at 0x1b4ee, gomez_maze_table: array(struct('cccc', %i[mound_lon mound_lat stump_lon stump_lat]))
  at 0x1b50e, :data

  at 0x1b5d6, *code
  at 0x29370, :data # Constants?
  at 0x2937a, :data # Misc string data for interfaces
  at 0x29796, :data
  at 0x2979a, *code
  at 0x317e2, :data # Misc string data for building search response
  at 0x318c6, *code

  at 0x4333a, *code # This might not be the start of the code!
  at 0x434c0, lut_nibbleswap: array(value_raw('C'))
  at 0x435c0, lut_hblit_offset: array(value_raw('n')) # 36-cell wide area for isometric view
  at 0x436e0, lut_vblit_offset: array(value_raw('n')) # 24-cell high area for isometric view
  at 0x43850, map_directory: directory
  at 0x44228 #, map_files: Bytes, LZSSData, 'n*' # World (77), generic (32), room (121), big room (22)
  at 0x5edc4, :data
  at 0x5f524, isotile_index: array(value_raw('N')) # Indexes data at 0x603e4
  at 0x603e4, isotile_data: bytes #, Struct, 'a*' # Image scanlines with flags - 00 = end - len/off; *pixels

  at 0x96120, lzss_directory: directory
  # at 0x9638c, lzss_files: Bytes, LZSSData, 'a*'
  # at 0xb3d40, scrolltext_epilogue: LZSSData, 'a*' # Images are signalled by 0x80 + portraid id
  # at 0xb6221, scrolltext_credits: LZSSData, 'a*' # Images are signalled by 0x80 + portraid id
  # at 0xb83a1, scrolltext_citizens: LZSSData, 'a*' # Images are signalled by 0x80 + portraid id

  at 0xb86ae, portrait_directory: directory
  at 0xb8a32, portrait_files: indexed(lzss) { @outputs[:portrait_directory].map { |e| e[:offset] } } # Struct, 'n16a*', *(0..15).to_a, :pixels, # Pixels are 8x8 cells in reading order

  at 0xcc9d8, palettes: array(array_n(16, struct('n', %i[raw], bitfields(:raw, r:4, g:4, b:4)))) # 16-colour 16-bit packed 0bgr x 16 entries

  # Static menus
  at 0xccdb8, menu_definitions: array(
    struct(
      'Z6C6', %i[text _f1 _f2 _f3 _f4 type n_entries],
      entries: array_n(:n_entries, struct('Z6C8', %i[text _f1 _f2 _f3 _f4 _f5 submenu_id value type]))
    )
  )

  at 0xcd430, menu_words: array(struct('CZ15', %i[flags name])) # Also includes character names
  at 0xcecf0, :data

  # FIXME: should be able to have an array field here.  This is what we get for using unpack.
  at 0xcf1ac, party_init_table: array(struct('n6nCCnCCnCC', %w[0 1 2 3 4 5 city time u2 mood loyalty u3 floor_loc u4 u5]))
  at 0xd1cfc, locations_table: array(struct('CCCCnnCC', [:equivalent_location, :city, :unk3, :unk4, :long, :lat, :floor, :type]))

  at 0xd2ec2, :table, array(bytes(12))
  at 0xd301e, sign_positions: array(struct('nnn', %w[lon lat unused]))
  at 0xd3102, :table, array(bytes(12))
  at 0xd601e, lockables_table: array(struct('nncc', %i[flags1 flags2 local_lon local_lat])) # Matches quest flag index
  at 0xd63e4, locations_something: array(bytes(4)) # Indexed by location ID
  at 0xd66a0, item_lists: array(struct('ccccnnn', %i[unk1 unk2 unk3 count unk4 menu_word table_offset])) # Indexes item_values
  at 0xd6768, item_values: array(struct('nn', %i[menu_word value])) # Game logic LUTs e.g. pricepoints, paper paragraph index
  at 0xd6b6c, spells: array(struct('Nn', %i[packed_data mana_cost])) # xxxxxRRR xDDDDDD1 x0x0xSSS SSxxxxxx S=11111 for mame spells???  Damage can be > 63 somehow
  at 0xd6e60, class_levels: array(array_n(10, struct('C', [:spell_limit]))) # Can cast anything less than limit

  at 0xd6eba, dictionary: indexed { @outputs[:dictionary_index] }

  at 0xdc0c0, :data
  at 0xdc0c2, dictionary_index: array(value_raw('n'))

  at 0xddbd8, paragraph_directory: directory
  at 0xe0a18, paragraph_wordlists: array(
    struct('n', %i[bf], bitfields(:bf, 16, punc: 2, word_id: 14), word: proc do |f, struct|
      @outputs[:dictionary][struct[:word_id] - 1]
    end)
  )

  at 0xeb770, :data
  at 0xed0e8, :data

  at 0xfd07c, ea_checksum: m68k # Sum 0x3f41f dwords from 0x0, skipping 0x18c, compare
  at 0xfd0cc, wabbits: bytes # ff ff ff ff...
end
