shared_examples_for "an API command" do
  let(:params)  { {} }
  let(:command) { described_class.new(params) }

  subject       { command }
  its(:to_a)    { is_expected.to eq(output) }
end
