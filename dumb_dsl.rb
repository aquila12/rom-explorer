ZEROBLOCK = ("\0" * 1024).freeze

def sizeof(format)
  ZEROBLOCK.unpack(format).pack(format).bytesize
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

def layout(filename = nil, &block)
  @layout = filename ? proc { File.open(filename, 'rb', &block) } : block
end

def unmake(f)
  @regions = {}
  @layout.call(f)
  starts = @regions.keys.sort
  @upper = (starts + [f.size]).each_cons(2).to_h

  starts.map do |start|
    f.seek(start)
    @regions[start].transform_values { |p| p.call(f) }
  end.inject(:merge)
end

