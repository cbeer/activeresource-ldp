require 'spec_helper'
require 'http_logger'

describe "ActiveRecord::Ldp", vcr: true do
  
  before do
    HttpLogger.logger = Logger.new(STDERR) if ENV['DEBUG']

    class SomeModel < ActiveResource::Ldp::Base
      self.site = "http://localhost:8080/rest/"
      belongs_to :parent, class_name: "SomeModel"
      schema do
        attribute 'title', :string, predicate: RDF::DC.title
        attribute 'parent_id', :string, predicate: RDF::URI("http://fedora.info/definitions/v4/repository#hasParent")
      end
      
      belongs_to_many :members, class_name: "SomeModel"
    end
    
    class FoafModel < ActiveResource::Ldp::Base
      self.site = "http://localhost:8080/rest/foafs"
      schema_from_vocabulary RDF::FOAF
    end
  end
  
  after(:all) do
    SomeModel.delete 'xyz' rescue nil
    SomeModel.delete 'xyz1' rescue nil
    SomeModel.delete 'xyz2' rescue nil
    SomeModel.delete 'abc/def/ghi' rescue nil
    SomeModel.delete 'a/b/c' rescue nil
    SomeModel.delete 'foafs' rescue nil
    SomeModel.delete 'parent' rescue nil
  end

  describe ".exists?" do
    it "should work" do
      expect(SomeModel.exists?("1")).to be_false
    end
  end

  describe "create and reload" do
    it "should work" do
      m = SomeModel.new(id: 'xyz')
      m.save!
      m.reload
      expect(SomeModel.exists? "xyz").to be_true
      expect(m.uuid).to_not be_blank
    end
  end
  
  describe "create and set values" do
    it "should work" do
      m = SomeModel.new(id: 'xyz1', title: 'some title')
      expect(m.title).to eq "some title"
      m.save!
      m.reload
      expect(m.title).to eq "some title"
    end
  end
  
  describe "create and update values" do
    it "should work" do
      m = SomeModel.new(id: 'xyz2', title: 'some title')
      expect(m.title).to eq "some title"
      m.save!
      m.title = 'a new title'
      m.save!
      m.reload
      expect(m.title).to eq "a new title"
    end
  end
  
  describe "create with hierarchy" do
    it "should work" do
      m = SomeModel.new(id: 'abc/def/ghi')
      m.save!
      expect(m.id).to eq 'abc/def/ghi'
    end
  end
  
  describe "parent relation" do
    it "should work" do
      m = SomeModel.new(id: 'a/b/c')
      m.save!
      expect(m.parent).to_not be_blank
      expect(m.parent).to eq SomeModel.find('a/b')
    end
  end
  
  describe "members relation" do
    it "should work" do
      m = SomeModel.new(id: 'parent')
      m.save!
      
      child = SomeModel.new(id: 'parent/child')
      child.save!

      m.reload
      
      expect(m.members).to_not be_blank
      expect(m.members.first).to be_a_kind_of(SomeModel)
      expect(m.members.first.uuid).to eq child.uuid
    end
  end
  
  describe "rdf model" do
    it "should work" do
      SomeModel.create(id: 'foafs')
    
      m = FoafModel.new
      m.lastName = "Smith"
      m.save!
      m.reload
      expect(m.lastName).to eq "Smith"
    end
  end
  
  describe "absolute path" do
    it "should work" do
      m = SomeModel.find('/')
      expect(m.members).to_not be_blank
      expect(m.members.first).to be_a_kind_of(SomeModel)
    end
  end
  
end
