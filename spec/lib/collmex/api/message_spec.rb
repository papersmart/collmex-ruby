require "spec_helper"

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Rueckmeldungen
describe Collmex::Api::Message do

  context "Success" do
    it_behaves_like "an API command" do
      let(:params)   { { type: "S" } }
      let(:output)   { ["MESSAGE", "S", nil, "", nil] }

      its(:success?) { should eq(true)  }
      its(:failed?)  { should eq(false) }
      its(:result)   { should eq(:success) }
    end
  end

  context "Warning" do
    it_behaves_like "an API command" do
      let(:params)   { { type: "W" } }
      let(:output)   { ["MESSAGE", "W", nil, "", nil] }

      its(:success?) { should eq(false) }
      its(:failed?)  { should eq(true)  }
      its(:result)   { should eq(:warning) }
    end
  end

  context "Error" do
    it_behaves_like "an API command" do
      let(:params)   { { type: "E" } }
      let(:output)   { ["MESSAGE", "E", nil, "", nil] }

      its(:success?) { should eq(false) }
      its(:failed?)  { should eq(true)  }
      its(:result)   { should eq(:error) }
    end
  end

  context "Undefined" do
    it_behaves_like "an API command" do
      let(:params)   { nil }
      let(:output)   { ["MESSAGE", "", nil, "", nil] }

      its(:success?) { should eq(false) }
      its(:failed?)  { should eq(true)  }
      its(:result)   { should eq(:undefined) }
    end
  end
end
