# frozen_string_literal: true

RSpec.describe OmniAI::Anthropic::Chat::ChoiceSerializer do
  let(:context) { OmniAI::Anthropic::Chat::CONTEXT }

  describe ".serialize" do
    subject(:serialize) { described_class.serialize(choice, context:) }

    let(:choice) { OmniAI::Chat::Choice.new(message:) }
    let(:message) { OmniAI::Chat::Message.new(role: "user", content: [text]) }
    let(:text) { OmniAI::Chat::Text.new("Greetings!") }

    let(:data) do
      {
        role: "user",
        content: [
          {
            text: "Greetings!",
            type: "text",
          },
        ],
      }
    end

    it { is_expected.to eql(data) }
  end

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
      }
    end

    it { is_expected.to be_a(OmniAI::Chat::Choice) }
  end

  describe ".deserialize finish_reason mapping" do
    subject(:finish_reason) { described_class.deserialize(data, context:).finish_reason }

    let(:data) do
      {
        "role" => "assistant",
        "content" => [{ "type" => "text", "text" => "Hello!" }],
        "stop_reason" => stop_reason,
      }
    end

    {
      "end_turn" => :stop,
      "stop_sequence" => :stop,
      "max_tokens" => :length,
      "tool_use" => :tool_call,
      "refusal" => :filter,
      "pause_turn" => :other,
      "some_future_reason" => :other,
    }.each do |raw, expected|
      context "when stop_reason is #{raw.inspect}" do
        let(:stop_reason) { raw }

        it "normalizes the reason" do
          expect(finish_reason.reason).to eq(expected)
        end

        it "preserves the verbatim value" do
          expect(finish_reason.value).to eq(raw)
        end
      end
    end

    context "when stop_reason is absent" do
      let(:data) { { "role" => "assistant", "content" => [{ "type" => "text", "text" => "Hello!" }] } }

      it { is_expected.to be_nil }
    end
  end
end
