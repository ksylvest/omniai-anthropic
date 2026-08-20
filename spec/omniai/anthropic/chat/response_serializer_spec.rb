# frozen_string_literal: true

RSpec.describe OmniAI::Anthropic::Chat::ResponseSerializer do
  let(:context) { OmniAI::Anthropic::Chat::CONTEXT }

  describe ".serialize" do
    subject(:serialize) { described_class.serialize(response, context:) }

    let(:response) { OmniAI::Chat::Response.new(data: {}, choices:, usage:) }
    let(:choices) { [OmniAI::Chat::Choice.new(message:)] }
    let(:message) { OmniAI::Chat::Message.new(role: "user", content: [text]) }
    let(:text) { OmniAI::Chat::Text.new("Greetings!") }
    let(:usage) { OmniAI::Chat::Usage.new(input_tokens: 2, output_tokens: 3, total_tokens: 5) }

    let(:data) do
      {
        role: "user",
        content: [
          {
            text: "Greetings!",
            type: "text",
          },
        ],
        usage: {
          input_tokens: 2,
          output_tokens: 3,
          total_tokens: 5,
        },
      }
    end

    it { is_expected.to eql(data) }
  end

  describe ".deserialize" do
    subject(:deserialize) { described_class.deserialize(data, context:) }

    # Anthropic's `usage` object carries no `total_tokens` key. An earlier fixture here asserted one, which meant
    # this spec proved the deserializer could parse a shape the API never sends.
    #
    # Confirmed by capture: claude-opus-5 and claude-sonnet-5, POST /v1/messages, streaming and non-streaming,
    # 2026-08-20 — every response reported input_tokens, cache_creation_input_tokens, cache_read_input_tokens,
    # cache_creation, output_tokens, output_tokens_details, service_tier and inference_geo. No total_tokens.
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
        },
      }
    end

    it { is_expected.to be_a(OmniAI::Chat::Response) }
    it { expect(deserialize.usage.input_tokens).to be(2) }
    it { expect(deserialize.usage.output_tokens).to be(3) }

    it "reports no total, because Anthropic sends none" do
      expect(deserialize.usage.total_tokens).to be_nil
    end

    context "with a thinking breakdown" do
      let(:data) do
        {
          "role" => "user",
          "content" => [{ "text" => "Greetings!", "type" => "text" }],
          "usage" => {
            "input_tokens" => 2,
            "output_tokens" => 9,
            "output_tokens_details" => { "thinking_tokens" => 6 },
          },
        }
      end

      it "exposes the reasoning breakdown" do
        expect(deserialize.usage.thinking_tokens).to be(6)
      end

      it "leaves output_tokens alone, because Anthropic already counts reasoning in it" do
        expect(deserialize.usage.output_tokens).to be(9)
      end
    end
  end
end
