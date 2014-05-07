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

  def decode(ttl, headers = nil, path = nil)
    graph = RDF::Graph.new
    graph.from_ttl(ttl)

    h = {}

    subject = graph.subjects.select { |x| x.path == path }.first
    h[:id] = subject.to_s
    model.schema.each do |k, v|
      h[k] = graph.query(subject: subject, predicate: v['predicate']).map do |x|
        x.object
      end.first.to_s
    end
    
    h[:member_ids] = members(subject, graph)

    h[:graph] = graph
    
    h
  end
  
  private
  def members subject, graph
    return enum_for(:members, subject, graph) unless block_given?
    graph.query(subject: subject,  predicate: member_predicate(subject, graph)).map do |x| 
      yield x.object.to_s
    end
  end
  
  def member_predicate subject, graph
    graph.query(subject: subject, predicate: RDF::URI("http://www.w3.org/ns/ldp#hasMemberRelation")).map { |x| x.object }.first
  end
end
