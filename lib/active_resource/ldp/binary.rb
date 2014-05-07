class ActiveResource::Ldp::Binary < Activeresource::Ldp::Base
  def encode
    content
  end
  
  def format
    self._format || ActiveResource::Formats::IdentityFormat || super
  end
  
  schema do
    attribute 'content', nil
  end
end
