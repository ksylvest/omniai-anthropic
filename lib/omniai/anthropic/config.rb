# frozen_string_literal: true

module OmniAI
  module Anthropic
    # Config for the Anthropic `api_key` / `host` / `logger` / `version` / `chat_options`.
    class Config < OmniAI::Config
      attr_accessor :version, :chat_options

      def initialize
        super
        @api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
        @host = ENV.fetch('ANTHROPIC_HOST', 'https://api.anthropic.com')
        @version = ENV.fetch('ANTHROPIC_VERSION', '2023-06-01')
        @chat_options = { max_tokens: 4096 }
      end
    end
  end
end
