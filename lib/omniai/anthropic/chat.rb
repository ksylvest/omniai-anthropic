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
    #   completion.choice.message.content # '...'
    class Chat < OmniAI::Chat
      module Model
        CLAUDE_INSTANT_1_0 = 'claude-instant-1.2'
        CLAUDE_2_0 = 'claude-2.0'
        CLAUDE_2_1 = 'claude-2.1'
        CLAUDE_3_OPUS_20240229 = 'claude-3-opus-20240229'
        CLAUDE_3_HAIKU_20240307 = 'claude-3-haiku-20240307'
        CLAUDE_3_SONET_20240307 = 'claude-3-haiku-20240307'
        CLAUDE_3_5_SONET_20240620 = 'claude-3-5-sonnet-20240620'
        CLAUDE_OPUS = CLAUDE_3_OPUS_20240229
        CLAUDE_HAIKU = CLAUDE_3_HAIKU_20240307
        CLAUDE_SONET = CLAUDE_3_5_SONET_20240620
      end

      # @param [Media]
      # @return [Hash]
      # @example
      #   media = Media.new(...)
      #   MEDIA_SERIALIZER.call(media)
      MEDIA_SERIALIZER = lambda do |media, *|
        {
          type: media.kind, # i.e. 'image' / 'video' / 'audio' / ...
          source: {
            type: 'base64',
            media_type: media.type, # i.e. 'image/jpeg' / 'video/ogg' / 'audio/mpeg' / ...
            data: media.data,
          },
        }
      end

      # @return [Context]
      CONTEXT = Context.build do |context|
        context.serializers[:file] = MEDIA_SERIALIZER
        context.serializers[:url] = MEDIA_SERIALIZER
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
        messages = @prompt.messages.filter(&:user?)
        messages.map { |message| message.serialize(context: CONTEXT) }
      end

      # @return [String, nil]
      def system
        messages = @prompt.messages.filter(&:system?)
        messages.map(&:content).join("\n\n") if messages.any?
      end

      # @return [String]
      def path
        "/#{Client::VERSION}/messages"
      end

      private

      # @return [Array<Hash>, nil]
      def tools_payload
        @tools&.map do |tool|
          {
            name: tool.name,
            description: tool.description,
            input_schema: tool.parameters&.prepare,
          }.compact
        end
      end
    end
  end
end
