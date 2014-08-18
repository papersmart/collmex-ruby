require 'spec_helper'
require 'yaml'
require 'collmex'
require "vcr"

describe Collmex do
  it {is_expected.to respond_to :username}
  it {is_expected.to respond_to :password}
  it {is_expected.to respond_to :customer_id}
end

describe "CollmexIntegration" do

  before(:each) do
    Collmex.setup_login_data({username: 8866413, password: 2291502, customer_id: 104156})
  end

  after(:each) do
   # Collmex.setup_login_data
  end

  it "should work with the long form" do

    request = Collmex::Request.new

    c1 = request.add_command Collmex::Api::CustomerGet.new(customer_id: 9999)
    c2 = request.add_command Collmex::Api::AccdocGet.new()
    c3 = request.add_command Collmex::Api::AccdocGet.new(accdoc_id: 1)

    VCR.use_cassette('standard_request') do
      request.execute
    end
  end

  it "should work with the block form" do

   # ap  Collmex::Api::AccdocGet.new("ASDASD;2;2")

    request = ""
    VCR.use_cassette('standard_request2') do
      request = Collmex::Request.run do
        enqueue :customer_get, id: 9999
      end
    end

    VCR.use_cassette('standard_request') do
      expect(request.response.last.success?).to eql true
    end
  end
end
