module ActiveResource::Ldp::Associations::Builder
  class HasContent < ActiveResource::Associations::Builder::SingularAssociation
    self.macro = :belongs_to
    self.valid_options += [:path]

  end
end
