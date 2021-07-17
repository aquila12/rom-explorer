# frozen_string_literal: true

require_relative 'layoutable/layout'
require_relative 'layoutable/applied_layout'
require_relative 'layoutable/table'
require_relative 'layoutable/struct'

module Layoutable
  def self.included(includee)
    includee.extend(ClassMethods)
  end

  module ClassMethods
    def define_layout(&block)
      @layout = Layout.new
      @layout.instance_eval(&block)
    end

    def directory
      @layout.directory
    end

    def apply_to(data)
      AppliedLayout.new(data, directory)
    end

    attr_reader :layout
  end
end