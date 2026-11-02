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

  { menu_definitions:, quest_descriptor_table: }
end

def struct(size, format, names, *bitfields, **postprocessing)
  after = [*bitfields, postprocessing].inject(:merge)
  proc do |f, parent|
    values = f.read(size).unpack(format)
    names.zip(values).to_h.tap do |struct|
      after.each { |name, p| struct[name] = p.call(f, struct) }
    end
  end
end

def array_n(size, inner)
  raise ArgumentError, "no block given" unless inner.respond_to?(:call)

  proc do |f, parent = {}|
    n = size.is_a?(Symbol) ? parent.fetch(size) : size
    Array.new(n) { inner.call(f) }
  end
end

def array_u(upper, inner)
  raise ArgumentError, "no block given" unless inner.respond_to?(:call)

  proc do |f|
    arr = []
    while f.pos < upper
      arr << inner.call(f, arr)
    end
    arr
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

def implementation(f)
  f.seek(0xccdb8)
  menu_definitions = array_u(
    0xcd430, struct(
      12, 'Z6C6', %i[text _f1 _f2 _f3 _f4 type n_entries],
      entries: array_n(:n_entries, struct(14, 'Z6C8', %i[text _f1 _f2 _f3 _f4 _f5 submenu_id value type]))
    )
  ).call(f, nil)

  f.seek(0xd601e)
  quest_descriptor_table = array_u(
    0xd63e4, struct(
      6, 'nN', %i[bf1 filter],
      bitfields(:bf1, 16, initial_state: :b, type: 4, item_list: 5, item_index: 6)
    )
  ).call(f, nil)

  { menu_definitions:, quest_descriptor_table: }
end

# Strict testing of hash equality: order matters
module KeyOrderSensitivity
  def ==(other)
    super && keys == other.keys
  end
end

@timing = {}
def time(name)
  t0 = Time.now
  r = yield
  t1 = Time.now
  @timing[name] = t1 - t0
  r
end

File.open('rings.bin', 'rb') do |f|
  a1 = time(:ref) { reference_implementation(f) }
  f.seek(0)
  a2 = time(:imp) { implementation(f) }

  puts YAML.safe_dump(a2, stringify_names: true)

  Hash.prepend KeyOrderSensitivity
  warn a1 == a2 ? "PASS" : "FAIL"

  warn YAML.safe_dump(@timing, stringify_names: true)
end
