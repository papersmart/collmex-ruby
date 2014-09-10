require "spec_helper"

describe Collmex::Request do

  describe ".run" do
    before { allow_any_instance_of(described_class).to receive(:execute) }

    it "returns an instance of Collmex::Request" do
      expect(described_class.run).to be_a(described_class)
    end

    it "executes a given block" do
      expect_any_instance_of(described_class).to receive(:enqueue).with("arr").and_return("blaaaa")

      described_class.run do
        enqueue "arr"
      end
    end

    it "yields itself to the block if arity == 1" do
      described_class.run do |request|
        expect(request).to be_a(described_class)
      end
    end
  end

  describe ".uri" do
    let(:customer_id) { Collmex.config.customer_id }
    let(:api_uri)     { URI.parse("https://www.collmex.de/cgi-bin/cgi.exe?#{customer_id},0,data_exchange") }

    subject { described_class.uri }
    it      { is_expected.to eq(api_uri) }
  end

  subject { described_class.new }

  describe "#initialize" do
    let(:config) { OpenStruct.new }

    it "raises an error if no credentials given" do
      expect { described_class.new(config) }.to raise_error("No credentials for Collmex given.")
    end

    it "should add the Login command to its own queue" do
      request = described_class.new
      expect(request.commands.count).to eq(1)
    end
  end

  describe "#success?" do
  end

  describe "#add_command" do

    it "should add the given command to its command array" do
      request = described_class.new
      expect(request).to be_a described_class

      request.commands = Array.new
      request.add_command "asd"
      expect(request.commands.count).to eq(1)
    end
  end

  describe "#classify" do
    subject { described_class }

    specify do
      expect(subject.classify(:accdoc_get)).to eq("AccdocGet")
      expect(subject.classify(:accDoc_get)).to eq("AccdocGet")
    end
  end

  describe "#enqueue" do

    context "given a symbol command" do
      let(:request) { described_class.new }

      it "should return a command object" do
        expect(request.enqueue(:accdoc_get)).to be_a Collmex::Api::AccdocGet
      end

      it "should enqueue the given comands" do
        initial_count = request.commands.count
        request.enqueue :accdoc_get
        request.enqueue :accdoc_get, :accdoc_id => 1
        expect(request.commands.count).to equal (initial_count + 2)
      end
    end

    context "given a collmex api line object" do

      let(:request) { described_class.new }

      it "should retun the command object" do
        cmd_obj = Collmex::Api::AccdocGet.new
        expect(request.enqueue(cmd_obj)).to eq(cmd_obj)
      end

      it "should enqueue the command object" do
        initial_count = request.commands.count
        cmd_obj = Collmex::Api::AccdocGet.new
        request.enqueue cmd_obj
        expect(request.commands.count).to eq(initial_count + 1)
        expect(request.commands.last).to eq(cmd_obj)
      end
    end
  end

  describe ".execute" do

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow_any_instance_of(Net::HTTP).to receive(:request_post).and_return(response)
      allow(Collmex::Api).to receive(:parse_line)
    end

    let(:http) do
      http = double(Net::HTTP)
      allow(http).to receive("use_ssl=")
      allow(http).to receive("verify_mode=")
      allow(http).to receive(:request_post).and_return(response)
      http
    end

    let(:response) do
      response = double(Net::HTTPOK)
      allow(response).to receive(:body).and_return("fuckmehard")
      allow(response).to receive(:code).and_return(200)
      response
    end

    it "should create an instance of net::http" do
      expect(Net::HTTP).to receive(:new).and_return(http)
      subject.execute
    end

    it "should use ssl" do
      expect(http).to receive("use_ssl=").with(true)
      subject.execute
    end

    it "should not verify ssl" do
      expect(http).to receive("verify_mode=").with(OpenSSL::SSL::VERIFY_NONE)
      subject.execute
    end

    it "shoud do the post_request" do
      expect(http).to receive(:request_post).with(anything, anything,
        "Content-Type" => "text/csv"
      ).and_return(response)

      subject.execute
    end

    context "with a working connection" do

      it "should parse the response" do
        allow(subject).to receive(:parse_response).and_return([Collmex::Api::Accdoc.new])
        expect(subject).to receive(:parse_response)
        subject.execute
      end

      it "the response should be encoded in utf-8" do
        string = "Allgemeiner Gesch\xE4ftspartne".force_encoding("ASCII-8BIT")
        allow(response).to receive(:body).and_return(string)
        subject.execute

        expect(subject.instance_variable_get(:@raw_response)[:string].encoding.to_s).to eq("UTF-8")
      end
    end
  end
end
