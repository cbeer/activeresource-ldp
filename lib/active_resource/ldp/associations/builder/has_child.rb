module ActiveResource::Ldp::Associations::Builder
  class HasChild < ActiveResource::Associations::Builder::SingularAssociation
    self.macro = :has_one
    self.valid_options += [:path]
  end
end
