class ActiveResource::Formats::IdentityFormat
  
  def self.extension
  end

  def self.mime_type
    "*/*"
  end

  def self.decode(content, response, path)
    h[:content] = content
  end
end
