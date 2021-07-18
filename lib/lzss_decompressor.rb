# frozen_string_literal: true

# LSZZ 4k sliding window decompressor
class LZSSDecompressor
  def self.decompress(io)
    new(io).result
  end

  def initialize(io)
    @io = io
    @length = io.read(4).unpack1('V')
    @window = String.new(' ' * 4096)
    @windex = 0xfee # Scratchpad write starts at -18
    @output = String.new(capacity: @length)
    @flag = flag_reader
    @byte = byte_reader
  end

  def result
    decompress unless @done

    @output
  end

  private

  def decompress
    @length.times do
      c = @byte.next
      @output += c
      @window[@windex] = c
      @windex = (@windex + 1) & 0xfff
    end
    @done = true
  end

  def flag_reader
    Enumerator.new do |y|
      loop do
        flags = @io.read(1).unpack1('C')
        8.times { |b| y << flags[b].nonzero? }
      end
    end
  end

  def byte_reader
    Enumerator.new do |y|
      loop do
        @flag.next ? y << @io.read(1) : extract_compressed(y)
      end
    end
  end

  def extract_compressed(yielder)
    ctrlw = @io.read(2).unpack1('v')
    length = 3 + ctrlw[8..11] # 3 to 18
    index = (ctrlw[12..15] << 8) + ctrlw[0..7]

    length.times do |i|
      yielder << @window[(index + i) & 0xfff]
    end
  end
end
