# frozen_string_literal: true

RSpec.describe OmniAI::Anthropic::Chat::ToolSerializer do
  let(:context) { OmniAI::Anthropic::Chat::CONTEXT }

  describe "#serialize" do
    subject(:serialize) { tool.serialize(context:) }

    let(:tool) { OmniAI::Tool.new(-> { "..." }, name: "weather", description: "Finds the current weather") }

    it { expect(serialize).to eql(name: "weather", description: "Finds the current weather") }
  end
end
