require 'yaml'

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

def struct(format, names, *bitfields, **postprocessing)
  size = sizeof(format)
  after = [*bitfields, postprocessing].inject(:merge)
  proc do |f, parent|
    values = f.read(size).unpack(format)
    names.zip(values).to_h.tap do |struct|
      after.each { |name, p| struct[name] = p.call(f, struct) }
    end
  end
end

def array_raw(format)
  size = sizeof(format)
  proc { |f| f.read(size).unpack(format) }
end

def value_raw(format)
  size = sizeof(format)
  proc { |f| f.read(size).unpack1(format) }
end

def array_n(size, inner)
  raise ArgumentError, "no block given" unless inner.respond_to?(:call)

  proc do |f, parent = {}|
    n = size.is_a?(Symbol) ? parent.fetch(size) : size
    Array.new(n) { inner.call(f) }
  end
end


def bit(bitfield, bits, type = :u)
  proc do |f, parent|
    v = parent[bitfield][bits]
    case type
    when :u then v
    when :b then !v.zero?
    when :i then
      b = bits.is_a?(Range) ? bits.size : 1
      v[b - 1].zero? ? v : v - (1 << b)
    end
  end
end

def bitfield_shorthand_spec(spec)
  case spec
  when Enumerable then spec.first
  when Numeric then spec.negative? ? [:i, spec] : [:u, spec]
  when :b then [:b, 1]
  end
end

def bitfields(bitfield, total_size = 0, **info)
  pos = total_size
  rev = total_size.positive?
  info.transform_values do |spec|
    type, size = bitfield_shorthand_spec(spec)
    bits =  rev ? (pos - size)...pos : pos...(pos + size)
    pos += rev ? -size : size
    bit(bitfield, bits, type)
  end
end

def at(addr, **what)
  @regions[addr] = what
end

def array(inner)
  raise ArgumentError, "no block given" unless inner.respond_to?(:call)

  proc do |f|
    upper = @upper[f.pos]
    arr = []
    while f.pos < upper
      arr << inner.call(f, arr)
    end
    arr.pop if f.pos > upper
    arr
  end
end

def layout
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

ZEROBLOCK = "\0" * 1024
def sizeof(format)
  ZEROBLOCK.unpack(format).pack(format).bytesize
end

def implementation(f)
  @regions = {}
  layout
  starts = @regions.keys.sort
  @upper = (starts + [f.size]).each_cons(2).to_h

  starts.map do |start|
    f.seek(start)
    @regions[start].transform_values { |p| p.call(f) }
  end.inject(:merge)
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
  a2 = time(:imp, 100) { implementation(f) }

  Hash.prepend KeyOrderSensitivity
  warn a1 == a2 ? "PASS" : "FAIL"

  File.write('ref.yaml', YAML.safe_dump(a1, stringify_names: true))
  File.write('imp.yaml', YAML.safe_dump(a2, stringify_names: true))

  warn YAML.safe_dump(@timing, stringify_names: true)
  warn (@timing[:imp] / @timing[:ref])
end
