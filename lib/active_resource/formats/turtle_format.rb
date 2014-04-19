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

    h = Hash[model.schema.map do |k, v|
      [
        k, 
        graph.query(predicate: v['predicate']).map { |x| x.object }.first
      ]
    end]
  end
end
