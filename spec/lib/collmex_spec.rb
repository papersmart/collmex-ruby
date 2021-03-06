require 'spec_helper'
require 'yaml'
require 'collmex'
require "vcr"

describe "CollmexIntegration" do
  it "works with the long form" do
    request = Collmex::Request.new

    c1 = request.add_command Collmex::Api::CustomerGet.new(customer_id: 9999)
    c2 = request.add_command Collmex::Api::AccdocGet.new
    c3 = request.add_command Collmex::Api::AccdocGet.new(accdoc_id: 1)

    VCR.use_cassette("standard_request") do
      request.execute
    end
  end

  it "works with the block form" do
    request = nil

    VCR.use_cassette("standard_request2") do
      request = Collmex::Request.run do
        enqueue :customer_get, id: 9999
      end
    end

    VCR.use_cassette("standard_request") do
      expect(request.response.last).to be_success
    end
  end
end
