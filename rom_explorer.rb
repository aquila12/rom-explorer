#!/usr/bin/env ruby
# ROM explorer utility

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')

require 'layoutable'
require 'irb'

def rom(filename)
  @data = File.binread(filename)
  @data.length
end

def apply(layout)
  @rom = layout.apply_to(@data)
end

binding.irb
