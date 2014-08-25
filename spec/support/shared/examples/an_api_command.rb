shared_examples_for "an API command" do
  let(:params)  { {} }
  let(:command) { described_class.new(params) }

  subject    { command }
  it         { is_expected.to be_a(Collmex::Api::Line) }
  its(:to_a) { is_expected.to eq(output) }
end
