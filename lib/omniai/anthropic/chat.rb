# frozen_string_literal: true

module OmniAI
  module Anthropic
    # A Anthropic chat implementation.
    #
    # Usage:
    #
    #   chat = OmniAI::Anthropic::Chat.new(client: client)
    #   chat.completion('Tell me a joke.')
    #   chat.completion(['Tell me a joke.'])
    #   chat.completion({ role: 'user', content: 'Tell me a joke.' })
    #   chat.completion([{ role: 'system', content: 'Tell me a joke.' }])
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

      protected

      # @param response [HTTP::Response]
      # @return [OmniAI::Anthropic::Chat::Stream]
      def stream!(response:)
        raise Error, "#{self.class.name}#stream! unstreamable" unless @stream

        Stream.new(response:).stream! { |chunk| @stream.call(chunk) }
      end

      # @param response [HTTP::Response]
      # @param response [OmniAI::Anthropic::Chat::Completion]
      def complete!(response:)
        Completion.new(data: response.parse)
      end

      # @return [Hash]
      def payload
        OmniAI::Anthropic.config.chat_options.merge({
          model: @model,
          messages: messages.filter { |message| !message[:role].eql?(OmniAI::Chat::Role::SYSTEM) },
          system:,
          stream: @stream.nil? ? nil : !@stream.nil?,
          temperature: @temperature,
        }).compact
      end

      # @return [String, nil]
      def system
        messages = self.messages.filter { |message| message[:role].eql?(OmniAI::Chat::Role::SYSTEM) }
        messages << { role: OmniAI::Chat::Role::SYSTEM, content: OmniAI::Chat::JSON_PROMPT } if @format.eql?(:json)

        messages.map { |message| message[:content] }.join("\n\n") if messages.any?
      end

      # @return [String]
      def path
        "/#{OmniAI::Anthropic::Client::VERSION}/messages"
      end
    end
  end
end
