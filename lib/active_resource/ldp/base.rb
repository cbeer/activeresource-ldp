require 'active_resource'
class ActiveResource::Ldp::Base < ActiveResource::Base
  class_attribute :include_format_in_path
  self.include_format_in_path = false

  class << self
    def schema(&block)
      if block_given?
        schema_definition = ActiveResource::Ldp::Schema.new
        schema_definition.instance_eval(&block)

        # skip out if we didn't define anything
        return unless schema_definition.attrs.present?

        @known_attributes ||= []

        schema_definition.attrs.each do |k,v|
          schema[k] = v
          @known_attributes << k
        end

        schema
      else
        @schema ||= default_schema
      end
    end
    
    def default_schema
      if self == ActiveResource::Ldp::Base
        {}.with_indifferent_access
      else
        ActiveResource::Ldp::Base.schema
      end
    end
    
    def element_name
      @element_name ||= ''
    end
    
    def collection_name
      @collection_name ||= ''
    end
    
    def format
      self._format || model_specific_turtle_parser || super
    end
    
    def model_specific_turtle_parser
      ActiveResource::Formats::TurtleFormat.new(self)
    end
    
    def headers
      super.merge({ "Prefer" => "return=minimal"})
    end
  end
  
  def encode options = {}
    #if options[:only]
    #else
      graph = RDF::Graph.new
      
      attributes.except(:id).each do |k,v|
        Array(v).each do |val|
          graph << [RDF::URI(''), schema[k]['predicate'], val]
        end
      end
      graph.dump(:ttl)
  #  end
  end
  
  schema do
    attribute 'uuid', :string, predicate: RDF::URI('http://fedora.info/definitions/v4/repository#uuid')
  end
  
  protected
  # Create (i.e., \save to the remote service) the \new resource.
  def create
    run_callbacks :create do
      connection.post(collection_path, encode, self.class.headers.merge(instance_headers)).tap do |response|
        self.id = response['Location'].sub(self.class.site.to_s, "")
        get_response = connection.get(self.class.element_path(self.id), self.class.headers)
        load_attributes_from_response(get_response)
      end
    end
  end
  
  def instance_headers
    h = { }
    h['Slug'] = attributes['id'] if attributes['id']
    h
  end
end