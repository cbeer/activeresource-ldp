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
      super.merge({ "Prefer" => "return=representation; include=\"http://fedora.info/definitions/v4/repository#InboundReferences\"; omit=\"#{::Ldp.prefer_containment}\""})
    end
    
    def element_path(id, prefix_options = {}, query_options = nil)
      real_id = id.to_s.sub(site.to_s, "")
      check_prefix_options(prefix_options)

      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}#{collection_name}/#{URI.parser.escape real_id.to_s}#{format_extension}#{query_string(query_options)}".gsub(/\/+/, '/')
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
    
    def fetch_and_decode path, headers
      response = connection.get(path, headers)
      format.decode(response.body, response, path)
    end
  end
  
  def encode options = {}
    graph = RDF::Graph.new
    
    attributes.except(:id, :graph).each do |k,v|
      Array(v).each do |val|
        graph << [RDF::URI(''), schema[k]['predicate'], val]
      end
    end
    graph.dump(:ttl)
  end
  
  def encode_patch
    subject = RDF::URI.new nil
    
    patterns = changes.map do |k, (was,is)|
      RDF::Query::Pattern.new(subject, schema[k]['predicate'], k.to_sym).to_s
    end.join("\n")
    
    query = "DELETE { \n"
    query += patterns

    query += "\n}\n"

    query += "INSERT { \n"
    query += 
      changes.reject { |k, (was,is)| is.nil? }.map do |k, (was,is)|
        RDF::Query::Pattern.new(subject: subject, predicate: schema[k]['predicate'], object: is).to_s
      end.join("\n")

    query += "\n}\n"

    query += "WHERE { \n"
    query += patterns
    query += "\n}"
    
    query
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
      connection.post(collection_path, encode, self.class.headers.merge(instance_create_headers)).tap do |response|
        self.id = URI.parse(response['Location']).to_s
        load_attributes_from_response(response)
      end
    end
  end
  
  # Update the resource on the remote service.
  def update
    run_callbacks :update do
      if changed_attributes.present?
        connection.patch(element_path(prefix_options), encode_patch, self.class.headers.merge("Content-Type" => "application/sparql-update"))
      end
    end
  end
  
  def load_attributes_from_response response
    if (response_code_allows_body?(response.code) && response['Location'].blank? &&
        (response['Content-Length'].nil? || response['Content-Length'] != "0") &&
        !response.body.nil? && response.body.strip.size > 0)
      load(self.class.format.decode(response.body), true, true)
      @persisted = true
    elsif response['Location']
      load(fetch_and_decode(self.class.element_path(response['Location'].sub(self.class.site.to_s, "")), self.class.headers), true, true)
      @persisted = true
    end
  end
  
  def fetch_and_decode *args
    self.class.send(:fetch_and_decode, *args)
  end
  
  def instance_create_headers
    h = { }
    h['Slug'] = slug if slug
    h
  end
  
  def slug
    attributes['id'] if attributes['id']
  end
end
