# frozen_string_literal: true

module OmniAI
  module Anthropic
    # An Anthropic client implementation. Usage:
    #
    # w/ `api_key``:
    #   client = OmniAI::Anthropic::Client.new(api_key: '...')
    #
    # w/ ENV['ANTHROPIC_API_KEY']:
    #
    #   ENV['ANTHROPIC_API_KEY'] = '...'
    #   client = OmniAI::Anthropic::Client.new
    #
    # w/ config:
    #
    #   OmniAI::Anthropic.configure do |config|
    #     config.api_key = '...'
    #   end
    #
    #   client = OmniAI::Anthropic::Client.new
    class Client < OmniAI::Client
      VERSION = 'v1'

      # @param api_key [String] optional - defaults to `OmniAI::Anthropic.config.api_key`
      # @param host [String] optional - defaults to `OmniAI::Anthropic.config.host`
      def initialize(
        api_key: OmniAI::Anthropic.config.api_key,
        version: OmniAI::Anthropic.config.version,
        logger: OmniAI::Anthropic.config.logger,
        host: OmniAI::Anthropic.config.host
      )
        raise(ArgumentError, %(ENV['ANTHROPIC_API_KEY'] must be defined or `api_key` must be passed)) if api_key.nil?

        super(api_key:, logger:)

        @host = host
        @version = version
      end

      # @return [HTTP::Client]
      def connection
        HTTP
          .headers('x-api-key': @api_key)
          .headers('anthropic-version': @version)
          .persistent('https://api.anthropic.com')
      end

      # @raise [OmniAI::Error]
      #
      # @param messages [String, Array, Hash]
      # @param model [String] optional
      # @param format [Symbol] optional :text or :json
      # @param temperature [Float, nil] optional
      # @param stream [Proc, nil] optional
      #
      # @return [OmniAI::Chat::Completion]
      def chat(messages, model: Chat::Model::HAIKU, temperature: nil, format: nil, stream: nil)
        Chat.process!(messages, model:, temperature:, format:, stream:, client: self)
      end
    end
  end
end
