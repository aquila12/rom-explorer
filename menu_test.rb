require 'yaml'
require_relative 'dumb_dsl'

def hex(n) = "0x%05x" % n

def reference_implementation(f)
  menu_definitions = []
  f.seek(0xccdb8)
  while(f.pos < 0xcd430)
    mvalues = f.read(12).unpack 'Z6C6'
    struct = %i[text _f1 _f2 _f3 _f4 type n_entries].zip(mvalues).to_h

    menu_definitions << struct.merge(entries:
      Array.new(struct[:n_entries]) do |n|
        evalues = f.read(14).unpack 'Z6C8'
        %i[text _f1 _f2 _f3 _f4 _f5 submenu_id value type].zip(evalues).to_h
      end
    )
  end

  quest_descriptor_table = []
  f.seek(0xd601e)
  while(f.pos < 0xd63e4)
    qvalues = f.read(6).unpack 'nN'
    struct = %i[bf1 filter].zip(qvalues).to_h

    b = struct[:bf1]
    quest_descriptor_table << struct.merge(
      initial_state: !b[15].zero?,
      type: b[11..14],
      item_list: b[6..10],
      item_index: b[0..5]
    )
  end

  { lut_nibbleswap: f.pread(256, 0x434c0).unpack('C256'), menu_definitions:, quest_descriptor_table: }
end

layout do
  at 0xccdb8, menu_definitions: array(
    struct(
      'Z6C6', %i[text _f1 _f2 _f3 _f4 type n_entries],
      entries: array_n(:n_entries, struct('Z6C8', %i[text _f1 _f2 _f3 _f4 _f5 submenu_id value type]))
    ))
  at 0xcd430

  at 0xd601e, quest_descriptor_table: array(
    struct(
      'nN', %i[bf1 filter],
      bitfields(:bf1, 16, initial_state: :b, type: 4, item_list: 5, item_index: 6)
    )
  )
  at 0xd63e4

  at 0x434c0, lut_nibbleswap: array_raw('C256')
end

# Strict testing of hash equality: order matters
module KeyOrderSensitivity
  def ==(other)
    super && keys == other.keys
  end
end

@timing = {}
def time(name, count)
  t0 = Time.now
  n = 0
  while(n < count)
    r = yield
    n += 1
  end
  t1 = Time.now
  @timing[name] = (t1 - t0) / count
  r
end

File.open('rings.bin', 'rb') do |f|
  f.read
  a1 = time(:ref, 100) { reference_implementation(f) }
  a2 = time(:imp, 100) { unmake(f) }

  Hash.prepend KeyOrderSensitivity
  warn a1 == a2 ? "PASS" : "FAIL"

  File.write('ref.yaml', YAML.safe_dump(a1, stringify_names: true))
  File.write('imp.yaml', YAML.safe_dump(a2, stringify_names: true))

  warn YAML.safe_dump(@timing, stringify_names: true)
  warn (@timing[:imp] / @timing[:ref])
end
