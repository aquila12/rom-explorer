#!/usr/bin/env ruby
# ROM explorer utility

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')

require 'layoutable'
require 'irb'

def rom(filename)
  @data = File.binread(ARGV.shift)
end

binding.irb
