class ActiveResource::Formats::TurtleFormat
  attr_reader :model
  
  def initialize model
    @model = model
  end

  def extension
    "ttl"
  end

  def mime_type
    "text/turtle"
  end

  def decode(ttl)
    graph = RDF::Graph.new
    graph.from_ttl(ttl)

    h = {}
    model.schema.each do |k, v|
      h[k] = graph.query(predicate: v['predicate']).map { |x| x.object }.first
    end
    
    h[:member_ids] = members(graph)

    h[:graph] = graph
    
    h
  end
  
  private
  def members graph
      graph.query(predicate: 
          graph.query(predicate: RDF::URI("http://www.w3.org/ns/ldp#hasMemberRelation")).map { |x| x.object }.first
      ).map { |x| x.object.to_s }
  end
end
