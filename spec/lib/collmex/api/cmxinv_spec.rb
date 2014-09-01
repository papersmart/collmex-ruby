require "spec_helper"

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_rechnungen
describe Collmex::Api::Cmxinv do
  it_behaves_like "an API command" do
    let(:params) { { id: 1, customer_id: 9999 } }
    let(:output) { ["CMXINV", 1, nil, nil, 1, nil, 9999, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, nil, nil, nil, "", nil, nil, nil, "", "", "", "", nil, nil, nil, nil, "", nil, nil, "", nil, nil, nil, nil, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, "", "", "", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil] }
  end
end
