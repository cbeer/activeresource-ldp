module ActiveResource::Ldp::PolymorphicFinder
  def self.find id
    obj = ActiveResource::Ldp::Base.find(id)
    class_name = obj.graph.query(subject: RDF::URI.new(id), predicate: RDF.type).select do |x|
      x.object.to_s.start_with? ActiveResource::Ldp::RDF_TYPE_PREFIX
    end.first

    if class_name
      class_name.object.to_s.sub(ActiveResource::Ldp::RDF_TYPE_PREFIX, "").classify.constantize.find(id)
    else
      obj
    end
    
  end
end
