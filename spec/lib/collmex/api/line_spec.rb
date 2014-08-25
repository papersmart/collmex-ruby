require "spec_helper"

describe Collmex::Api::Line do
  sample_spec = [
    { name: :identifier , type: :string   , fix: "BLA" },
    { name: :b          , type: :currency              },
    { name: :c          , type: :float                 },
    { name: :d          , type: :integer               },
    { name: :e          , type: :date                  },
  ]

  empty_hash   = { identifier: "BLA", b: nil, c: nil, d: nil, e: nil }
  empty_array  = ["BLA", nil, nil, nil, nil]
  filled_array = ["BLA", 20, 5.1, 10, Date.parse("12.10.1985")]
  filled_csv   = "BLA;0,20;5,10;10;19851012\n"

  subject { described_class.new }
  before  { allow(subject.class).to receive(:specification).and_return(sample_spec) }

  it { is_expected.to respond_to :to_csv }
  it { is_expected.to respond_to :to_a }
  it { is_expected.to respond_to :to_s }
  it { is_expected.to respond_to :to_h }

  describe ".hashify" do

    it "should parse the fields" do
      string    = "BLA"
      integer   = 421
      float     = 123.23
      currency  = 200
      date      = Date.parse("12.10.1985")

      output = { identifier: string, b: currency, c: float, d: integer, e: Date.parse("12.10.1985") }

      allow(described_class).to receive(:specification).and_return(sample_spec)
      allow(Collmex::Api).to receive(:parse_field).with(anything(),:string).and_return string
      allow(Collmex::Api).to receive(:parse_field).with(anything(),:float).and_return float
      allow(Collmex::Api).to receive(:parse_field).with(anything(),:integer).and_return integer
      allow(Collmex::Api).to receive(:parse_field).with(anything(),:currency).and_return currency
      allow(Collmex::Api).to receive(:parse_field).with(anything(),:date).and_return date

      tests = [
        [1,2,3,4],
        [1,nil,3],
        [1],
        {a: 1, b:nil},
        {},
        {c: 3},
        "1;2;3",
        "1;-2;3",
        "1;-2,5;3",
        ";;3",
      ]

      tests.each do |testdata|
        expect(described_class.hashify(testdata)).to eql output
      end
    end

    it "should set default values when nothing given" do
      sample_default_spec = [
        { name: :a,       type: :string,      default: "fixvalue" },
        { name: :b,       type: :currency,    default: 899 },
        { name: :c,       type: :integer,     default: 10 },
        { name: :d,       type: :float,       default: 2.99 },
      ]
      sample_default_outcome = {a: "fixvalue", b: 899, c: 10, d: 2.99}
      allow(described_class).to receive(:specification).and_return sample_default_spec
      expect(described_class.hashify([])).to eql sample_default_outcome
    end

    it "should overwrite default values when data is given" do
      sample_default_spec = [
        { name: :a,       type: :string,      default: "fixvalue" },
        { name: :b,       type: :currency,    default: 899 },
        { name: :c,       type: :integer,     default: 10 },
        { name: :d,       type: :float,       default: 2.99 },
      ]
      sample_default_outcome = {a: "asd", b: 12, c: 1, d: 1.0}
      allow(described_class).to receive(:specification).and_return sample_default_spec
      expect(described_class.hashify({a: "asd", b: 12, c: 1, d: 1})).to eql sample_default_outcome
    end

    it "should ignore given values for fix-value-fields" do
      sample_fix_spec = [
        { name: :a,       type: :string,      fix: "fixvalue" },
        { name: :b,       type: :currency,    fix: 899 },
        { name: :c,       type: :integer,     fix: 10 },
        { name: :d,       type: :float,       fix: 2.99 },
      ]
      sample_fix_outcome = {a: "fixvalue", b: 899, c: 10, d: 2.99}
      allow(described_class).to receive(:specification).and_return sample_fix_spec
      expect(described_class.hashify([])).to eql sample_fix_outcome
    end
  end

  describe ".default_hash" do
    it "should hold a specification" do
      allow(described_class).to receive(:specification).and_return([])
      expect(described_class.default_hash).to eql({})

      allow(described_class).to receive(:specification).and_return(sample_spec)
      expect(described_class.default_hash).to eql(empty_hash)
    end
  end

  describe "#initialize" do
    it "should raise an error if the specification is empty and the class is not Collmex::Api::Line" do
      allow(described_class).to receive(:specification).and_return({})
      if described_class.name == "Collmex::Api::Line"
        expect { described_class.new }.not_to raise_error
      else
        expect { described_class.new }.to raise_error "#{described_class.name} has no specification"
      end
    end

    it "should set the instance_variable hash" do
      expect(subject.instance_variable_get(:@hash)).to be_a Hash
    end

    context "no params given" do
      it "should build the specified but empty hash" do
        allow(described_class).to receive(:default_hash).and_return(empty_hash)
        line = described_class.new
        expect(line.to_h).to eql(empty_hash)
      end
    end

    context "something given" do
      it "should build the specified and filled hash" do
        input = { a: "bla" }
        output = empty_hash.merge(input)

        allow(described_class).to receive(:default_hash).and_return(empty_hash)
        allow(described_class).to receive(:hashify).and_return(output)
        line = described_class.new(input)
        expect(line.to_h).to eql (output)
      end
    end
  end

  describe "#to_csv" do
    it "should represent the request as csv" do
      allow(described_class).to receive(:specification).and_return(sample_spec)
      subject.instance_variable_set(:@hash, described_class.hashify(filled_array))
      expect(subject.to_csv).to eql filled_csv
    end
  end

  describe "#to_h" do
    it "should return the hash" do
      h = { first: 1, second: 2 }
      subject.instance_variable_set(:@hash, h)
      expect(subject.to_h).to eql h
    end
  end

  describe "#to_a" do
    it "should return the empty_hash translated to an array" do
      allow(described_class).to receive(:specification).and_return(sample_spec)
      expect(subject.to_a).to eql empty_array
    end
  end
end
