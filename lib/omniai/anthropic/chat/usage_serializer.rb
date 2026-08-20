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

          # Only overwrite when the vendor container is actually present. A payload produced by `Usage#serialize`
          # carries base's own `thinking_tokens` key and no `output_tokens_details`, so assigning unconditionally
          # would clobber a correctly-parsed value with nil and break the round-trip. `unless nil?` rather than
          # `||=`, so a reported zero from the wire still wins over base's nil.
          thinking_tokens = data.dig("output_tokens_details", "thinking_tokens")
          usage.thinking_tokens = thinking_tokens unless thinking_tokens.nil?

          usage
        end
      end
    end
  end
end
