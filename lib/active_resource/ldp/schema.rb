require 'active_resource/schema'
module ActiveResource # :nodoc:
  module Ldp
    class Schema < ActiveResource::Schema# :nodoc:
      def attribute(name, type, options = {})
        raise ArgumentError, "Unknown Attribute type: #{type.inspect} for key: #{name.inspect}" unless type.nil? || Schema::KNOWN_ATTRIBUTE_TYPES.include?(type.to_s)

        the_type = type.to_s
        @attrs[name.to_s] = options.merge(type: the_type)
        self
      end
    end  
  end
end
