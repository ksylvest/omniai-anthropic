# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      # Overrides choice serialize / deserialize.
      module ChoiceSerializer
        # Maps Anthropic `stop_reason` values onto the normalized OmniAI::Chat::FinishReason symbols. `pause_turn`
        # is intentionally absent (a continuation signal, neither a stop nor a filter) — it falls through to `:other`.
        FINISH_REASONS = {
          "end_turn" => OmniAI::Chat::FinishReason::STOP,
          "stop_sequence" => OmniAI::Chat::FinishReason::STOP,
          "max_tokens" => OmniAI::Chat::FinishReason::LENGTH,
          "tool_use" => OmniAI::Chat::FinishReason::TOOL_CALL,
          "refusal" => OmniAI::Chat::FinishReason::FILTER,
        }.freeze

        # @param choice [OmniAI::Chat::Choice]
        # @param context [Context]
        # @return [Hash]
        def self.serialize(choice, context:)
          choice.message.serialize(context:)
        end

        # @param data [Hash]
        # @param context [Context]
        # @return [OmniAI::Chat::Choice]
        def self.deserialize(data, context:)
          message = OmniAI::Chat::Message.deserialize(data, context:)
          finish_reason = OmniAI::Chat::FinishReason.deserialize(data["stop_reason"], table: FINISH_REASONS)
          OmniAI::Chat::Choice.new(message:, finish_reason:)
        end
      end
    end
  end
end
