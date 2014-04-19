require 'spec_helper'
require 'http_logger'

describe "ActiveRecord::Ldp" do
  before do
    HttpLogger.logger = Logger.new(STDERR) if ENV['DEBUG']

    class SomeModel < ActiveResource::Ldp::Base
      self.site = "http://localhost:8080/rest/"
      schema do
        attribute 'title', :string, predicate: RDF::DC.title
      end
    end
  end
  
  after(:all) do
    SomeModel.delete 'xyz' rescue nil
    SomeModel.delete 'xyz1' rescue nil
    SomeModel.delete 'xyz2' rescue nil
    SomeModel.delete 'abc/def/ghi' rescue nil
  end

  it "should work" do
    expect(SomeModel.exists?("1")).to be_false
  end

  it "should work" do
    m = SomeModel.new(id: 'xyz')
    m.save!
    m.reload
    expect(SomeModel.exists? "xyz").to be_true
    expect(m.uuid).to_not be_blank
  end
  
  it "should work" do
    m = SomeModel.new(id: 'xyz1', title: 'some title')
    expect(m.title).to eq "some title"
    m.save!
    m.reload
    expect(m.title).to eq "some title"
  end
  
  it "should work" do
    m = SomeModel.new(id: 'xyz2', title: 'some title')
    expect(m.title).to eq "some title"
    m.save!
    m.title = 'a new title'
    m.save!
    m.reload
    expect(m.title).to eq "a new title"
  end
  
  it "should work" do
    m = SomeModel.new(id: 'abc/def/ghi')
    m.save!
    expect(m.id).to eq 'abc/def/ghi'
  end
end
