require "spec_helper"

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_umsaetze
describe Collmex::Api::Cmxums do
  it_behaves_like "an API command" do
    let(:params) { { customer_id: 9999 } }
    let(:output) { ["CMXUMS", 9999, 1, nil, "", nil, nil, nil, nil, nil, nil, nil, nil, "", nil, nil, "", nil, nil, nil, nil, nil, nil, "", nil, "", "", ""] }
  end
end
