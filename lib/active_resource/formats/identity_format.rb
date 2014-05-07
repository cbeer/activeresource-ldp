class ActiveResource::Formats::IdentityFormat
  
  def self.extension
  end

  def self.mime_type
  end

  def decode(content)
    h[:content] = content
  end
end
