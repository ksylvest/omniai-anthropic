# frozen_string_literal: true

RSpec.describe OmniAI::Anthropic::Chat::UsageSerializer do
  let(:context) { OmniAI::Anthropic::Chat::CONTEXT }

  describe ".deserialize" do
    subject(:deserialize) { described_class.deserialize(data, context:) }

    context "with a reasoning breakdown" do
      # Captured: claude-opus-5, POST /v1/messages, non-streaming, thinking effort "max", 2026-08-20.
      # Trimmed to the token fields; `service_tier` and `inference_geo` omitted as irrelevant here.
      let(:data) do
        {
          "input_tokens" => 72,
          "cache_creation_input_tokens" => 0,
          "cache_read_input_tokens" => 0,
          "output_tokens" => 2388,
          "output_tokens_details" => { "thinking_tokens" => 912 },
        }
      end

      it { expect(deserialize).to be_a(OmniAI::Chat::Usage) }
      it { expect(deserialize.input_tokens).to be(72) }
      it { expect(deserialize.thinking_tokens).to be(912) }

      it "leaves output_tokens as reported, because Anthropic already counts reasoning in it" do
        expect(deserialize.output_tokens).to be(2388)
      end

      it "keeps thinking_tokens a subset of output_tokens" do
        expect(deserialize.thinking_tokens).to be <= deserialize.output_tokens
      end

      it "reports no total, because Anthropic sends no total_tokens key" do
        expect(deserialize.total_tokens).to be_nil
      end
    end

    context "with a streamed reasoning breakdown" do
      # Captured: claude-opus-5, POST /v1/messages, streaming, thinking effort "max", 2026-08-20 — the assembled
      # payload after Stream#message_delta. Anthropic sends this breakdown only on the final `message_delta`.
      let(:data) do
        {
          "input_tokens" => 72,
          "output_tokens" => 3052,
          "output_tokens_details" => { "thinking_tokens" => 1377 },
        }
      end

      it { expect(deserialize.thinking_tokens).to be(1377) }
      it { expect(deserialize.output_tokens).to be(3052) }
    end

    context "with a reasoning breakdown reporting zero" do
      # Captured: claude-sonnet-5, POST /v1/messages, thinking effort "medium", 2026-08-20 — adaptive thinking
      # declined to think, and the API still reported the breakdown with a value of zero.
      let(:data) do
        {
          "input_tokens" => 89,
          "output_tokens" => 466,
          "output_tokens_details" => { "thinking_tokens" => 0 },
        }
      end

      it "keeps a wire-reported zero, rather than collapsing it to nil" do
        expect(deserialize.thinking_tokens).to be(0)
      end
    end

    context "without a reasoning breakdown" do
      let(:data) { { "input_tokens" => 2, "output_tokens" => 3 } }

      it "leaves thinking_tokens nil rather than reporting zero" do
        expect(deserialize.thinking_tokens).to be_nil
      end
    end
  end
end
