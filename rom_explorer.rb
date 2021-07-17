#!/usr/bin/env ruby
# ROM explorer utility

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')

require 'layoutable'
require 'irb'

def rom(filename)
  @data = File.binread(filename)
  @data.length.tap { |l| puts "Loaded #{l} bytes" }
end

def apply(layout)
  @rom = layout.apply_to(@data)
end

def pwd
  @cwd ||= []
end

def cd(*args)
  args.each do |d|
    case d
    when '..' then @cwd.pop
    when '.' then @cwd
    when '/' then @cwd = []
    else @cwd << d
    end
  end
  item
end

def item
  (!@cwd || @cwd.empty?) ? @rom : @rom.dig(*@cwd)
end

while(arg = ARGV.shift)
  case arg
  when '-r'
    rom ARGV.shift
  when '-l'
    load ARGV.shift
  when /^-/
    warn "Unknown switch #{arg}"
    exit 1
  else
    warn "Unknown parameter #{arg}"
    exit 1
  end
end

binding.irb
