#!/usr/bin/env ruby
# frozen_string_literal: true

# Fix ROM checksum
# Only works on linear binaries

File.open(ARGV.shift, 'r+b') do |f|
  f.seek(0x200)
  sum = f.read.unpack('n*').inject(:+) & 0xffff
  puts format('Calculated 0x%04x', sum)

  f.seek(0x18e)
  cs = f.read(2).unpack1('n')
  puts format('Found 0x%04x', cs)

  exit 0 if cs == sum

  puts 'Fixing'
  f.seek(0x18e)
  f.write([sum].pack('n'))
end
