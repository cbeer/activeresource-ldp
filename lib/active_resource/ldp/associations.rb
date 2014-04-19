module ActiveResource::Ldp::Associations
  module Builder
    autoload :BelongsToMany,   'active_resource/ldp/associations/builder/belongs_to_many'
  end
  
  def belongs_to_many(name, options={})
    Builder::BelongsToMany.build(self, name, options)
  end

  # Defines the belongs_to association finder method
  def defines_belongs_to_many_finder_method(method_name, association_model, finder_key)
    ivar_name = :"@#{method_name}"
    define_method(method_name) do
      if instance_variable_defined?(ivar_name)
        instance_variable_get(ivar_name)
      elsif attributes.include?(method_name)
        attributes[method_name]
      elsif attributes.include?("#{method_name.to_s.singularize}_ids")
        instance_variable_set(ivar_name, self.class.collection_parser.new(Array(attributes["#{method_name.to_s.singularize}_ids"]).map { |x| SomeModel.find(x) }))
      else
        instance_variable_set(ivar_name, self.class.collection_parser.new)
      end
    end
  end

end
