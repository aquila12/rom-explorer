#!/usr/bin/env ruby
# frozen_string_literal: true

# Rings of Power location extractor

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")

require 'layoutable'
require_relative 'romlayout'

ROM = RingsOfPower.apply_to(File.binread(ARGV.shift))

case ARGV.shift
when nil
  pred = proc { true }
when '-l'
  long = ARGV.shift.to_i
  lat = ARGV.shift.to_i
  pred = proc { |l| l.values_at(:long, :lat) == [long, lat] }
when '-n'
  long = ARGV.shift.to_i
  lat = ARGV.shift.to_i
  distance = ARGV.shift.to_i
  distance2 = distance * distance
  pred = proc do |l|
    x, y = l.values_at(:long, :lat)
    ((x - long)**2 + (y - lat)**2) < distance2
  end
when '-i'
  id = ARGV.shift.to_i(16)
  pred = proc { |l| l[:id] == id }
when '-t'
  type = ARGV.shift.to_i(16)
  pred = proc { |l| l[:type] == type }
end

ROM[:locations_table].load_all

FORMAT = '%<lat>d %<long>d: %<type>02x %<floor>02x %<unk1>02x %<unk2>02x %<unk3>02x %<unk4>02x'
puts(ROM[:locations_table].find_all(&pred).map { |l| format FORMAT, l })
