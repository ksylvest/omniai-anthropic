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
        HAIKU = 'claude-3-haiku-20240307'
        SONNET = 'claude-3-sonnet-20240229'
        OPUS = 'claude-3-opus-20240229'
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
