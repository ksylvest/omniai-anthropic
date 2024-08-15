# frozen_string_literal: true

RSpec.describe OmniAI::Anthropic::Chat::PayloadSerializer do
  let(:context) { OmniAI::Anthropic::Chat::CONTEXT }

  describe '.serialize' do
    subject(:serialize) { described_class.serialize(payload, context:) }

    let(:payload) { OmniAI::Chat::Payload.new(choices:, usage:) }
    let(:choices) { [OmniAI::Chat::Choice.new(message:)] }
    let(:message) { OmniAI::Chat::Message.new(role: 'user', content: [text]) }
    let(:text) { OmniAI::Chat::Text.new('Greetings!') }
    let(:usage) { OmniAI::Chat::Usage.new(input_tokens: 2, output_tokens: 3, total_tokens: 5) }

    let(:data) do
      {
        role: 'user',
        content: [
          {
            text: 'Greetings!',
            type: 'text',
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

  describe '.deserialize' do
    subject(:deserialize) { described_class.deserialize(data, context:) }

    let(:data) do
      {
        'role' => 'user',
        'content' => [
          {
            'text' => 'Greetings!',
            'type' => 'text',
          },
        ],
        'usage' => {
          'input_tokens' => 2,
          'output_tokens' => 3,
          'total_tokens' => 5,
        },
      }
    end

    it { is_expected.to be_a(OmniAI::Chat::Payload) }
  end
end
