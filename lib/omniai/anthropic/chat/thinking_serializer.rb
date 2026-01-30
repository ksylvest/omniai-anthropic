# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      # Overrides thinking serialize / deserialize.
      module ThinkingSerializer
        # @param data [Hash]
        # @param context [Context]
        #
        # @return [OmniAI::Chat::Thinking]
        def self.deserialize(data, context: nil) # rubocop:disable Lint/UnusedMethodArgument
          OmniAI::Chat::Thinking.new(data["thinking"], metadata: { signature: data["signature"] })
        end

        # @param thinking [OmniAI::Chat::Thinking]
        # @param context [Context]
        #
        # @return [Hash]
        def self.serialize(thinking, context: nil) # rubocop:disable Lint/UnusedMethodArgument
          {
            type: "thinking",
            thinking: thinking.thinking,
            signature: thinking.metadata[:signature],
          }.compact
        end
      end
    end
  end
end
