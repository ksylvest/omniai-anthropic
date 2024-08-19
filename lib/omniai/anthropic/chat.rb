# frozen_string_literal: true

module OmniAI
  module Anthropic
    # An Anthropic chat implementation.
    #
    # Usage:
    #
    #   completion = OmniAI::Anthropic::Chat.process!(client: client) do |prompt|
    #     prompt.system('You are an expert in the field of AI.')
    #     prompt.user('What are the biggest risks of AI?')
    #   end
    #   completion.text # '...'
    class Chat < OmniAI::Chat
      module Model
        CLAUDE_INSTANT_1_0 = 'claude-instant-1.2'
        CLAUDE_2_0 = 'claude-2.0'
        CLAUDE_2_1 = 'claude-2.1'
        CLAUDE_3_OPUS_20240229 = 'claude-3-opus-20240229'
        CLAUDE_3_HAIKU_20240307 = 'claude-3-haiku-20240307'
        CLAUDE_3_SONNET_20240307 = 'claude-3-sonnet-20240307'
        CLAUDE_3_5_SONNET_20240620 = 'claude-3-5-sonnet-20240620'
        CLAUDE_OPUS = CLAUDE_3_OPUS_20240229
        CLAUDE_HAIKU = CLAUDE_3_HAIKU_20240307
        CLAUDE_SONNET = CLAUDE_3_5_SONNET_20240620
      end

      DEFAULT_MODEL = Model::CLAUDE_SONNET

      # @return [Context]
      CONTEXT = Context.build do |context|
        context.serializers[:tool] = ToolSerializer.method(:serialize)

        context.serializers[:file] = MediaSerializer.method(:serialize)
        context.serializers[:url] = MediaSerializer.method(:serialize)

        context.serializers[:choice] = ChoiceSerializer.method(:serialize)
        context.deserializers[:choice] = ChoiceSerializer.method(:deserialize)

        context.serializers[:tool_call] = ToolCallSerializer.method(:serialize)
        context.deserializers[:tool_call] = ToolCallSerializer.method(:deserialize)

        context.serializers[:function] = FunctionSerializer.method(:serialize)
        context.deserializers[:function] = FunctionSerializer.method(:deserialize)

        context.deserializers[:content] = ContentSerializer.method(:deserialize)
        context.deserializers[:payload] = PayloadSerializer.method(:deserialize)
      end

      # @return [Hash]
      def payload
        OmniAI::Anthropic.config.chat_options.merge({
          model: @model,
          messages:,
          system:,
          stream: @stream.nil? ? nil : !@stream.nil?,
          temperature: @temperature,
          tools: tools_payload,
        }).compact
      end

      # @return [Array<Hash>]
      def messages
        messages = @prompt.messages.reject(&:system?)
        messages.map { |message| message.serialize(context:) }
      end

      # @return [String, nil]
      def system
        messages = @prompt.messages.filter(&:system?)
        return if messages.empty?

        messages.filter(&:text?).map(&:text).join("\n\n")
      end

      # @return [String]
      def path
        "/#{Client::VERSION}/messages"
      end

      protected

      # @return [Context]
      def context
        CONTEXT
      end

      private

      # @return [Array<Hash>, nil]
      def tools_payload
        @tools.map { |tool| tool.serialize(context:) } if @tools&.any?
      end
    end
  end
end
