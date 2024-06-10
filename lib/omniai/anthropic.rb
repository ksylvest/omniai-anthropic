# frozen_string_literal: true

require 'event_stream_parser'
require 'omniai'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.push_dir(__dir__, namespace: OmniAI)
loader.setup

module OmniAI
  # A namespace for everything Anthropic.
  module Anthropic
    # @return [OmniAI::Anthropic::Config]
    def self.config
      @config ||= Config.new
    end

    # @yield [OmniAI::Anthropic::Config]
    def self.configure
      yield config
    end
  end
end
