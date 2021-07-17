# frozen_string_literal: true

module Layoutable
  class Struct
    def self.new(data, format, *labels)
      fields = data.unpack(format)
      return Hash[labels.zip(fields)] unless labels.empty?

      fields.length > 1 ? fields : fields.first
    end
  end
end
