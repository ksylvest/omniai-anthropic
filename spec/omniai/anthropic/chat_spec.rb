# frozen_string_literal: true

RSpec.describe OmniAI::Anthropic::Chat do
  let(:client) { OmniAI::Anthropic::Client.new }

  describe '#completion' do
    subject(:completion) { described_class.process!(prompt, client:, model:) }

    let(:model) { OmniAI::Anthropic::Chat::Model::CLAUDE_HAIKU }

    context 'with a string prompt' do
      let(:prompt) { 'Tell me a joke!' }

      before do
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .with(body: OmniAI::Anthropic.config.chat_options.merge({
            messages: [{ role: 'user', content: prompt }],
            model:,
          }))
          .to_return_json(body: {
            type: 'message',
            role: 'assistant',
            model:,
            content: [
              {
                type: 'text',
                text: 'Two elephants fall off a cliff. Boom! Boom!',
              },
            ],
            usage: {
              input_tokens: 32,
              output_tokens: 64,
            },
          })
      end

      it { expect(completion.choice.message.role).to eql('assistant') }
      it { expect(completion.choice.message.content).to eql('Two elephants fall off a cliff. Boom! Boom!') }
    end

    context 'with an array prompt' do
      let(:prompt) do
        OmniAI::Chat::Prompt.build do |prompt|
          prompt.system('You are a helpful assistant.')
          prompt.user('What is the capital of Canada?')
        end
      end

      before do
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .with(body: OmniAI::Anthropic.config.chat_options.merge({
            system: 'You are a helpful assistant.',
            messages: [
              { role: 'user', content: 'What is the capital of Canada?' },
            ],
            model:,
          }))
          .to_return_json(body: {
            type: 'message',
            role: 'assistant',
            model:,
            content: [
              {
                type: 'text',
                text: 'The capital of Canada is Ottawa.',
              },
            ],
            usage: {
              input_tokens: 32,
              output_tokens: 64,
            },
          })
      end

      it { expect(completion.choice.message.role).to eql('assistant') }
      it { expect(completion.choice.message.content).to eql('The capital of Canada is Ottawa.') }
    end

    context 'with a temperature' do
      subject(:completion) { described_class.process!(prompt, client:, model:, temperature:) }

      let(:prompt) { 'Pick a number between 1 and 5.' }
      let(:temperature) { 2.0 }

      before do
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .with(body: OmniAI::Anthropic.config.chat_options.merge({
            messages: [
              { role: 'user', content: 'Pick a number between 1 and 5.' },
            ],
            model:,
            temperature:,
          }))
          .to_return_json(body: {
            type: 'message',
            role: 'assistant',
            model:,
            content: [
              {
                type: 'text',
                text: '3',
              },
            ],
            usage: {
              input_tokens: 32,
              output_tokens: 64,
            },
          })
      end

      it { expect(completion.choice.message.role).to eql('assistant') }
      it { expect(completion.choice.message.content).to eql('3') }
    end

    context 'when formatting as JSON' do
      subject(:completion) { described_class.process!(prompt, client:, model:, format: :json) }

      let(:prompt) do
        OmniAI::Chat::Prompt.build do |prompt|
          prompt.system(OmniAI::Chat::JSON_PROMPT)
          prompt.user('What is the name of the dummer for the Beatles?')
        end
      end

      before do
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .with(body: OmniAI::Anthropic.config.chat_options.merge({
            system: OmniAI::Chat::JSON_PROMPT,
            messages: [
              { role: 'user', content: 'What is the name of the dummer for the Beatles?' },
            ],
            model:,
          }))
          .to_return_json(body: {
            type: 'message',
            role: 'assistant',
            model:,
            content: [
              {
                type: 'text',
                text: '{ "name": "Ringo" }',
              },
            ],
            usage: {
              input_tokens: 32,
              output_tokens: 64,
            },
          })
      end

      it { expect(completion.choice.message.role).to eql('assistant') }
      it { expect(completion.choice.message.content).to eql('{ "name": "Ringo" }') }
    end

    context 'when streaming' do
      subject(:completion) { described_class.process!(prompt, client:, model:, stream:) }

      let(:prompt) { 'Tell me a story.' }
      let(:stream) { proc { |chunk| } }

      before do
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .with(body: OmniAI::Anthropic.config.chat_options.merge({
            messages: [
              { role: 'user', content: 'Tell me a story.' },
            ],
            model:,
            stream: !stream.nil?,
          }))
          .to_return(body: <<~STREAM)
            event: message_start
            data: #{JSON.generate(type: 'message_start', message: { role: 'assistant' })}\n

            event: content_block_start
            data: #{JSON.generate(type: 'content_block_start', index: 0)}\n

            event: content_block_delta
            data: #{JSON.generate(type: 'content_block_delta', delta: { type: 'text_delta', text: 'A' })}\n

            event: content_block_delta
            data: #{JSON.generate(type: 'content_block_delta', delta: { type: 'text_delta', text: 'B' })}\n

            event: content_block_stop
            data: #{JSON.generate(type: 'content_block_stop', index: 0)}\n

            event: message_stop
            data: #{JSON.generate(type: 'message_stop')}\n
          STREAM
      end

      it do
        chunks = []
        allow(stream).to receive(:call) { |chunk| chunks << chunk }
        completion
        expect(chunks.map { |chunk| chunk.choice.delta.content }).to eql(%w[A B])
      end
    end

    context 'when using files / URLs' do
      let(:io) { Tempfile.new }

      let(:prompt) do
        OmniAI::Chat::Prompt.build do |prompt|
          prompt.user do |message|
            message.text('What are these photos of?')
            message.url('https://localhost/cat.jpg', 'image/jpeg')
            message.url('https://localhost/dog.jpg', 'image/jpeg')
            message.file(io, 'image/jpeg')
          end
        end
      end

      before do
        stub_request(:get, 'https://localhost/cat.jpg').to_return(body: 'cat')
        stub_request(:get, 'https://localhost/dog.jpg').to_return(body: 'dog')
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .with(body: OmniAI::Anthropic.config.chat_options.merge({
            messages: [
              {
                role: 'user',
                content: [
                  { type: 'text', text: 'What are these photos of?' },
                  { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: 'Y2F0' } },
                  { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: 'ZG9n' } },
                  { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: '' } },
                ],
              },
            ],
            model:,
          }))
          .to_return_json(body: {
            type: 'message',
            role: 'assistant',
            model:,
            content: [
              {
                type: 'text',
                text: 'They are a photo of a cat and a photo of a dog.',
              },
            ],
          })
      end

      it { expect(completion.choice.message.role).to eql('assistant') }
      it { expect(completion.choice.message.content).to eql('They are a photo of a cat and a photo of a dog.') }
    end
  end
end
