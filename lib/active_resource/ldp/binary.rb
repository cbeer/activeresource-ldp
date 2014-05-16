class ActiveResource::Ldp::Binary < ActiveResource::Ldp::Base
  def encode
    content
  end
  
  def format
    self._format || ActiveResource::Formats::IdentityFormat || super
  end
  
  def self.format
    ActiveResource::Formats::IdentityFormat
  end

  schema do
    attribute 'content', nil
    attribute "mimeType", :string
  end
end
