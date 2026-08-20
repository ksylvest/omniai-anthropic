# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      # Overrides usage deserialize to read Anthropic's reasoning breakdown.
      module UsageSerializer
        # Anthropic already counts reasoning inside `output_tokens` and reports the breakdown alongside it at
        # `output_tokens_details.thinking_tokens`, so the breakdown is read into `thinking_tokens` and the output
        # count is left exactly as reported. Adding the two together would double count.
        #
        # When streaming, the breakdown arrives only on the final `message_delta`.
        #
        # @param data [Hash]
        # @return [OmniAI::Chat::Usage]
        def self.deserialize(data, *)
          # Deserialize without a context so the generic flat parse runs rather than recursing into this method.
          usage = OmniAI::Chat::Usage.deserialize(data)
          usage.thinking_tokens = data.dig("output_tokens_details", "thinking_tokens")
          usage
        end
      end
    end
  end
end
