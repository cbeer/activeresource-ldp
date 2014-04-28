require 'active_resource'
class ActiveResource::Ldp::Base < ActiveResource::Base

  extend ActiveResource::Ldp::Associations
    
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
    
    def schema_from_vocabulary vocab
      vocab.public_methods(false).
            select { |x| vocab.properties.include?((vocab.send(x) rescue nil)) }.
            each do |k|
        schema[k] = { type: nil, predicate: vocab.send(k) }      
      end
      
    end
    
    def default_schema
      if self == ActiveResource::Ldp::Base
        {}.with_indifferent_access
      else
        ActiveResource::Ldp::Base.schema
      end
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
      super.merge({ "Prefer" => "return=representation; omit=\"#{::Ldp.prefer_containment}\""})
    end
    
    def element_path(id, prefix_options = {}, query_options = nil)
      real_id = id.to_s.sub(site.to_s, "")
      check_prefix_options(prefix_options)

      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}#{collection_name}/#{URI.parser.escape real_id.to_s}#{format_extension}#{query_string(query_options)}"
    end

    # Find every resource
    def find_every(options)
      puts options.inspect
      begin
        case from = options[:from]
        when Symbol
          instantiate_collection(get(from, options[:params]), options[:params])
        when String
          path = "#{from}#{query_string(options[:params])}"
          instantiate_collection(format.decode(connection.get(path, headers).body) || [], options[:params])
        else
          prefix_options, query_options = split_options(options[:params])
          path = collection_path(prefix_options, query_options)
          instantiate_collection( (format.decode(connection.get(path, headers).body) || []), query_options, prefix_options )
        end
      rescue ActiveResource::ResourceNotFound
        # Swallowing ResourceNotFound exceptions and return nil - as per
        # ActiveRecord.
        nil
      end
    end
  end
  
  def encode options = {}
    #if options[:only]
    #else
      graph = RDF::Graph.new
      
      attributes.except(:id, :graph).each do |k,v|
        Array(v).each do |val|
          graph << [RDF::URI(''), schema[k]['predicate'], val]
        end
      end
      graph.dump(:ttl)
  #  end
  end
  
  schema do
    attribute 'uuid', :string, predicate: RDF::URI('http://fedora.info/definitions/v4/repository#uuid')
    attribute 'graph', nil
    attribute 'parent_id', :string, predicate: RDF::URI("http://fedora.info/definitions/v4/repository#hasParent")
    ## 
    # the relation for member ids is dynamic and needs to be discovered from the response.
    # attribute 'member_ids', :string, predicate: RDF::URL("http://www.w3.org/ns/ldp#hasMemberRelation")
  end

  belongs_to_many :members, class_name: "ActiveResource::Ldp::PolymorphicFinder"
  belongs_to :parent, class_name: "ActiveResource::Ldp::PolymorphicFinder"

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
    h['Slug'] = slug if slug
    h
  end
  
  def slug
    attributes['id'] if attributes['id']
  end
end
