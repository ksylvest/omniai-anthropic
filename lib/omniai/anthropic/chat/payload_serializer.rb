# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      # Overrides payload serialize / deserialize.
      module PayloadSerializer
        # @param payload [OmniAI::Chat::Payload]
        # @param context [OmniAI::Context]
        # @return [Hash]
        def self.serialize(payload, context:)
          usage = payload.usage.serialize(context:)
          choice = payload.choice.serialize(context:)

          choice.merge({ usage: })
        end

        # @param data [Hash]
        # @param context [OmniAI::Context]
        # @return [OmniAI::Chat::Payload]
        def self.deserialize(data, context:)
          usage = OmniAI::Chat::Usage.deserialize(data['usage'], context:) if data['usage']
          choice = OmniAI::Chat::Choice.deserialize(data, context:)

          OmniAI::Chat::Payload.new(choices: [choice], usage:)
        end
      end
    end
  end
end
