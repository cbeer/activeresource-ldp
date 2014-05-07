require "active_resource/ldp/version"
require 'ldp'

module ActiveResource
  module Ldp
    RDF_TYPE_PREFIX = "info:active_resource/ldp#"
    require "active_resource/ldp/associations"
    require "active_resource/ldp/schema"
    require "active_resource/ldp/polymorphic_finder"
    require "active_resource/ldp/base"
    require "active_resource/formats/identity_format"
    require "active_resource/formats/turtle_format"
  end
end
