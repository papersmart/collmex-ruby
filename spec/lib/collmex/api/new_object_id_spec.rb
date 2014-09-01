require "spec_helper"

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_nummernvergabe
describe Collmex::Api::NewObjectId do
  it_behaves_like "an API command" do
    let(:params) { {} }
    let(:output) { ["NEW_OBJECT_ID", nil, nil, nil] }
  end
end
