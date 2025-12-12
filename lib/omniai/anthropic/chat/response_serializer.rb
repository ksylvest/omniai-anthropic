# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      # Overrides response serialize / deserialize.
      module ResponseSerializer
        # Overrides response deserialize.
        # @param data [Hash]
        # @param context [OmniAI::Context]
        #
        # @return [OmniAI::Chat::Response]
        def self.deserialize(data, context:)
          usage = OmniAI::Chat::Usage.deserialize(data["usage"], context:) if data["usage"]
          choice = OmniAI::Chat::Choice.deserialize(data, context:)

          OmniAI::Chat::Response.new(data:, choices: [choice], usage:)
        end
      end
    end
  end
end
