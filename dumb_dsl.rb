require 'yaml'

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

def at(addr, anon = nil, spec = nil, **what)
  if anon
    raise ArgumentError, 'at: multiple names specified' unless what.empty?

    name = "#{anon.to_s}_%05x" % addr
    reader = spec || bytes
  elsif what.empty?
    @regions[addr] = nil
    return
  else
    raise ArgumentError, 'at: multiple names specified' if what.length > 1

    name, reader = what.first
  end

  info = { name:, addr:, reader: }
  @regions[addr] = info
  @what[name] = info
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

def bytes(*params)
  length = params.shift if params.first.is_a? Integer
  postprocess = params

  proc do |f|
    d = f.read(length || (@upper[f.pos] - f.pos))
    postprocess.each { |p| d = p.call(d) }
    d
  end
end

def indexed(inner = proc { |f, l| f.read(l) }, &offsets)
  proc do |f|
    base = f.pos
    upper = @upper[f.pos]
    addrs = offsets.call + [upper]
    raise ArgumentError, 'Indexed offset is not integer' unless addrs.all? { |e| e.is_a? Integer }

    arr = []
    addrs.each_cons(2) do |a, b|
      f.seek(base + a)
      arr << inner.call(f, b - a)
      arr.pop if f.pos > upper
    end
    arr
  end
end

require_relative 'lib/lzss_decompressor'
require 'stringio'
def lzss(inner = proc { |f| f.read })
  proc do |f|
    StringIO.open(LZSSDecompressor.decompress(f), &inner)
  end
end

def layout(filename = nil, &block)
  @layout = block
  return unless filename

  basename = filename.sub(/\.[^\.]+$/, '')
  outfile = "#{basename}.yaml"

  data = File.open(filename, 'rb') { |f| unmake(f) }
  yaml = YAML.safe_dump(data, stringify_names: true)

  if File.exist? outfile
    content = File.read(outfile)
    if content == yaml
      warn "Output is the same; skipping write"
      return
    end
  end

  File.write(outfile, yaml)
end

def unmake(f)
  @regions = {}
  @what = {}
  @layout.call(f)
  starts = @regions.keys.sort
  @upper = (starts + [f.size]).each_cons(2).to_h

  @outputs = Hash.new do |outputs, name|
    info = @what.fetch(name)
    f.seek(info[:addr])
    outputs[name] = info[:reader].call(f)
  end

  @what.keys.to_h { |k| [k, @outputs[k]] }
end
