# frozen_string_literal: true

require_relative 'layoutable/layout'
require_relative 'layoutable/layout_dsl'
require_relative 'layoutable/applied_layout'
require_relative 'layoutable/container'
require_relative 'layoutable/table'
require_relative 'layoutable/struct'
require_relative 'layoutable/bytes'
require_relative 'layoutable/lzss_data'

# Wrapper around layout DSL
module Layoutable
  def self.included(includee)
    includee.extend(ClassMethods)
  end

  # Class methods for layouts
  module ClassMethods
    def define_layout(&block)
      dsl = LayoutDSL.new
      dsl.instance_eval(&block)
      @layout = dsl.build
    end

    attr_reader :layout

    def apply_to(data)
      AppliedLayout.new(data, layout)
    end
  end
end
