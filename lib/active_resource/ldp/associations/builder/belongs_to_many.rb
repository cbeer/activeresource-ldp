module ActiveResource::Ldp::Associations::Builder
  class BelongsToMany < ActiveResource::Associations::Builder::Association
    self.macro = :belongs_to

    def build
      validate_options
      model.create_reflection(self.class.macro, name, options).tap do |reflection|
        model.defines_belongs_to_many_finder_method(reflection.name, reflection.klass, reflection.foreign_key)
      end
    end
  end
end
