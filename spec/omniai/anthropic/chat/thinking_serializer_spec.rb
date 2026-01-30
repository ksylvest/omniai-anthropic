# frozen_string_literal: true

RSpec.describe OmniAI::Anthropic::Chat::ThinkingSerializer do
  describe ".deserialize" do
    it "creates Thinking with content and signature", :aggregate_failures do
      data = { "thinking" => "my thoughts", "signature" => "sig123" }
      thinking = described_class.deserialize(data)

      expect(thinking.thinking).to eq("my thoughts")
      expect(thinking.metadata[:signature]).to eq("sig123")
    end

    it "handles missing signature", :aggregate_failures do
      data = { "thinking" => "my thoughts" }
      thinking = described_class.deserialize(data)

      expect(thinking.thinking).to eq("my thoughts")
      expect(thinking.metadata[:signature]).to be_nil
    end

    it "handles nil thinking", :aggregate_failures do
      data = { "thinking" => nil, "signature" => "sig123" }
      thinking = described_class.deserialize(data)

      expect(thinking.thinking).to be_nil
      expect(thinking.metadata[:signature]).to eq("sig123")
    end
  end

  describe ".serialize" do
    it "returns hash with type, thinking, and signature" do
      thinking = OmniAI::Chat::Thinking.new("thoughts", metadata: { signature: "sig123" })
      result = described_class.serialize(thinking)

      expect(result).to eq({ type: "thinking", thinking: "thoughts", signature: "sig123" })
    end

    it "omits signature when not present" do
      thinking = OmniAI::Chat::Thinking.new("thoughts", metadata: {})
      result = described_class.serialize(thinking)

      expect(result).to eq({ type: "thinking", thinking: "thoughts" })
    end

    it "omits signature when nil" do
      thinking = OmniAI::Chat::Thinking.new("thoughts", metadata: { signature: nil })
      result = described_class.serialize(thinking)

      expect(result).to eq({ type: "thinking", thinking: "thoughts" })
    end
  end
end
