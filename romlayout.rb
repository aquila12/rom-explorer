# frozen_string_literal: true

# Rings of Power ROM layout
class RingsOfPower
  include Layoutable

  define_layout do # rubocop:disable Metrics/BlockLength
    size 0x100000

    code = ['code_%05x', :m68k]
    data = ['data_%05x', :bytes]
    lzss = ['lzss_%05x', LZSSData, 'a*']
    table = ['tabl_%05x', Table]

    structure :directory, Table, 10, 'NNn', :offset, :length, :type
    structure :m68k, :bytes
    structure :lzss_files, Bytes, LZSSData, 'a*'

    at 0x00000, :reset_state, Struct, 'NN', :init_sp, :init_pc
    at 0x00008, *data
    at 0x00100, :rom_header, :bytes
    at 0x00200, :bootloader, :m68k
    at 0x00290, *data

    at 0x002fa, *code
    at 0x0dd5c, :decompress_lzss, :m68k, note: 'Compression type 1, LZSS 4k sliding window'
    at 0x0de1a, :decompress_plain, :m68k, note: 'Compression type 0, straight data'
    at 0x0df58, *table, 4, 'N', note: 'Raw addresses into the ROM to the following section'
    at 0x0e358, *code, note: 'Lots of unrolled loops and unconditional branch to e3e2 - maybe blitter?'

    at 0x1107a, *code
    at 0x12072, :void_found_you, :m68k, note: 'May be an exception handler'
    at 0x13654, :archive_extract, :m68k, note: 'Look up and decompress, f(void *buffer, int index, void *table, void *data)'
    at 0x136fc, :decompress_para, :m68k, note: 'Compression type 5, n_bytes = f(int word_count, void *buffer, void *data)'
    at 0x1383d, *code

    at 0x197b0, *data

    at 0x1a710, :text_class_full, Table, 12, 'Z*'
    at 0x1a794, :text_class_abbr, Table, 4, 'Z*'
    at 0x1a7c0, :text_status_filler, Table, 6, 'Z*'
    at 0x1a7f0, :text_status_health, Table, 16, 'Z*'
    at 0x1a8c0, :text_status_mana, Table, 16, 'Z*'
    at 0x1a990, :text_status_mood, Table, 16, 'Z*'
    at 0x1aa60, :text_status_level, Table, 90, Table, 10, 'Z*', note: 'Untrained has no level vector'
    at 0x1ade4, *data
    at 0x1b298, :city_goods, Table, 2, 'CC', :export, :import, note: 'Half or double price'
    at 0x1b2e0, *data
    at 0x1b320, :text_title_scroller, Table, 42, 'a*'
    at 0x1b446, *data

    at 0x1b5d6, *code
    at 0x29370, *data, note: 'Constants?'
    at 0x2937a, *data, note: 'Misc string data for interfaces'
    at 0x29796, *data
    at 0x2979a, *code
    at 0x317e2, *data, note: 'Misc string data for building search response'
    at 0x318c6, *code

    at 0x4333a, *code, note: 'This might not be the start of the code!'
    at 0x434c0, :lut_nibbleswap, Struct, 'C*'
    at 0x435c0, :lut_hblit_offset, Struct, 'n*', note: '36-cell wide area for isometric view'
    at 0x436e0, :lut_vblit_offset, Struct, 'n*', note: '24-cell high area for isometric view'
    at 0x43850, :map_directory, :directory
    at 0x44228, :map_files, Bytes, LZSSData, 'n*', note: 'World (77), generic (32), room (121), big room (22)'
    at 0x5edc4, *data
    at 0x5f524, *table, 4, 'N', note: 'Indexes data at 0x603e4'
    at 0x603e4, *data, note: 'Appears to be image data, likely prepends scanline byte length, 00 = end'

    at 0xb3d40, :scrolltext_epilogue, LZSSData, 'a*', note: 'Images are signalled by 0x80 + portraid id'
    at 0xb41da, *lzss
    at 0xb5b33, *lzss
    at 0xb5e0c, *lzss
    at 0xb6221, :scrolltext_credits, LZSSData, 'a*', note: 'Images are signalled by 0x80 + portraid id'
    at 0xb666c, *lzss
    at 0xb83a1, :scrolltext_citizens, LZSSData, 'a*', note: 'Images are signalled by 0x80 + portraid id'

    at 0xb86ae, :portrait_directory, :directory
    at 0xb8a32, :portrait_files, Bytes, LZSSData, Struct, 'n16a*', *(0..15).to_a, :pixels,
      note: 'Pixels are 8x8 cells in reading order'
    at 0xcc9d8, :palettes, Table, 32, Struct, 'n*', note: '16-colour 16-bit packed 0bgr x 31 entries'

    at 0xccdb8, :menu_definitions, :bytes, note: 'Variable length Z6C6{Z6C8}[] - Static menus'
    at 0xcd430, :menu_words, Table, 16, 'CZ*', :flags, :name, note: 'Also includes character names'
    at 0xcecf0, *data

    at 0xcf1ac, *table, 24, 'a*'
    at 0xd1cfc, :locations_table, Table, 10, 'CCCCnnCC', :unk1, :unk2, :unk3, :unk4, :long, :lat, :floor, :type

    at 0xd2ec2, *table, 12, 'a*'
    at 0xd601e, *table, 6, 'a*'
    at 0xd63e4, *table, 4, 'a*'
    at 0xd66a0, :item_lists, Table, 10, 'ccccnnn', :unk1, :unk2, :unk3, :count, :unk4, :menu_word, :table_offset, note: 'Indexes item_values'
    at 0xd6768, :item_values, Table, 4, 'nn', :menu_word, :value, note: 'Game logic LUTs e.g. pricepoints, paper paragraph index'
    at 0xd6b6c, :spells, Table, 6, 'Nn', :packed_data, :mana_cost, note: 'xxxxxRRR xDDDDDD1 x0x0xSSS SSxxxxxx S=11111 for mame spells???  Damage can be > 63 somehow'
    at 0xd6e60, :class_levels, Table, 10, Table, 1, 'C', :spell_limit, note: 'Can cast anything less than limit'

    at 0xd6eba, :dictionary, Bytes, String
    at 0xdc0c0, *data
    at 0xdc0c2, :dictionary_index, Table, 2, Struct, 'n'

    at 0xddbd8, :paragraph_directory, :directory
    at 0xe0a18, :paragraph_wordlists, Bytes, Struct, 'n*', note: 'Top 2 bits for punctuation, rest for word id'

    at 0xeb770, *data
    at 0xed0e8, *data

    at 0xfd07c, :ea_checksum, :m68k, note: 'Sum 0x3f41f dwords from 0x0, skipping 0x18c, compare'
    at 0xfd0cc, :wabbits, :bytes, note: 'ff ff ff ff...'
  end
end
