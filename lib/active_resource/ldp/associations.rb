module ActiveResource::Ldp::Associations
  module Builder
    autoload :BelongsToMany,   'active_resource/ldp/associations/builder/belongs_to_many'
    autoload :HasChild,   'active_resource/ldp/associations/builder/has_child'
    autoload :HasContent,   'active_resource/ldp/associations/builder/has_content'
  end
  
  autoload :HasChildAssociation, 'active_resource/ldp/associations/has_child_association'
  
  def belongs_to_many(name, options={})
    Builder::BelongsToMany.build(self, name, options)
  end
  
  def has_child(name, options={})
    Builder::HasChild.build(self, name, options)
  end

  def has_content(options={})
    Builder::HasContent.build(self, :content, options)
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
  
  # Defines the belongs_to association finder method
  def defines_has_child_finder_method(method_name, association_model, child_path=nil)
    ivar_name = :"@#{method_name}"

    if method_defined?(method_name)
      instance_variable_set(ivar_name, nil)
      remove_method(method_name)
    end
    
    child_path ||= method_name

    define_method(method_name) do
      model = if persisted?
        real_id = id.to_s.sub(self.class.site.to_s, "")
        m = association_model.new(id: real_id + "/" + child_path)
        
        m if m.exists?
      end

      instance_variable_set(ivar_name, model)
    end
  end

  # Defines the belongs_to association finder method
  def defines_has_content_finder_method(method_name, association_model, child_path="fcr:content")
    ivar_name = :"@content"

    if method_defined?(method_name)
      instance_variable_set(ivar_name, nil)
      remove_method(method_name)
    end
    
    child_path ||= method_name

    define_method(method_name) do
      model = if persisted?
        real_id = id.to_s.sub(self.class.site.to_s, "")
        m = association_model.new(id: real_id + "/" + child_path)
        
        m if m.exists?
      end

      instance_variable_set(ivar_name, model)
    end
  end
end
