# frozen_string_literal: true

class ROM
  include Layoutable

  define_layout do
    size 0x100000

    code = ['code_%05x', :m68k]
    data = ['data_%05x', :bytes]
    table = ['tabl_%05x', Table]

    structure :directory, Table, 10, 'NNn', :offset, :length, :type
    structure :m68k, :bytes
    structure :lzss_file, :bytes  # One file
    structure :lzss_files, :bytes # Multiple files (offset-indexed)

    at 0x00000, :reset_state, Struct, 'NN', :init_sp, :init_pc
    at 0x00008, *data
    at 0x00100, :rom_header, :bytes
    at 0x00200, :bootloader, :m68k
    at 0x00290, *data

    at 0x002fa, *code
    at 0x0dd5c, :decompress_lzss, :m68k   # Type 1
    at 0x0de1a, :decompress_type0, :m68k  # Type 0
    at 0x0df58, *data

    at 0x1107a, *code
    at 0x12072, :void_found_you, :m68k
    at 0x13654, :archive_extract, :m68k # f(void *buffer, int index, void *table, void *data)
    at 0x136fc, :decompress_para, :m68k # Type 5 bytes_filled = f(int word_count, void *buffer, void *data);
    at 0x1383d, *code

    at 0x197b0, *data

    at 0x1a710, :text_class_full, Table, 12, 'Z*'
    at 0x1a794, :text_class_abbr, Table, 4, 'Z*'
    at 0x1a7c0, :text_status_filler, Table, 6, 'Z*'
    at 0x1a7f0, :text_status_health, Table, 16, 'Z*'
    at 0x1a8c0, :text_status_mana, Table, 16, 'Z*'
    at 0x1a990, :text_status_mood, Table, 16, 'Z*'
    at 0x1aa60, :text_status_level, Table, 90, Table, 10, 'Z*'
    at 0x1ade4, *data
    at 0x1b320, :text_title_scroller, Table, 42, 'a*'
    at 0x1b446, *data

    at 0x1b5d6, *code
    at 0x29370, *data # Constants?
    at 0x2937a, *data # Misc string data for interfaces
    at 0x29796, *data
    at 0x2979a, *code
    at 0x317e2, *data # Misc string data for building search response
    at 0x318c6, *code

    at 0x43006, *data

    at 0xb3d49, :scrolltext_epilogue, :lzss_file
    at 0xb41e0, *data, :bytes # Approx address
    at 0xb6226, :scrolltext_credits, :lzss_file
    at 0xb6680, *data, :bytes # Approx address
    at 0xb83a7, :scrolltext_citizens, :lzss_file
    at 0xb86a0, *data, :bytes # Approx address

    at 0xb86ae, :portrait_directory, :directory
    at 0xb8a32, :portrait_files, :lzss_files
  # Is this length correct?
    at 0xccdb8, :menu_definitions, :bytes # Variable length structure
    at 0xcd430, :people_items, Table, 16, 'cZ*', :flags, :name
    at 0xcecf0, *data

    at 0xcf1b0, *table, 24, 'a*'
    at 0xd1cfc, :locations_table, Table, 10, 'ccccnncc', :unk1, :unk2, :unk3, :unk4, :lat, :long, :floor, :type
    at 0xd2ec2, *table, 12, 'a*'
    at 0xd601e, *table, 6, 'a*'
    at 0xd66a2, *table, 10, 'a*'
    at 0xd676a, *table, 4, 'a*'
    at 0xd6b6a, *data

    at 0xd676a, :unknown_table, Table, 4, Struct, 'nn', :lat, :long
  end
end
