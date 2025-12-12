# frozen_string_literal: true

RSpec.describe OmniAI::Anthropic::Chat::ResponseSerializer do
  let(:context) { OmniAI::Anthropic::Chat::CONTEXT }

  describe ".deserialize" do
    subject(:deserialize) { described_class.deserialize(data, context:) }

    let(:data) do
      {
        "role" => "user",
        "content" => [
          {
            "text" => "Greetings!",
            "type" => "text",
          },
        ],
        "usage" => {
          "input_tokens" => 2,
          "output_tokens" => 3,
          "total_tokens" => 5,
        },
      }
    end

    it { is_expected.to be_a(OmniAI::Chat::Response) }
  end
end
