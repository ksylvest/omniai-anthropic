# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      # Overrides tool-call response serialize / deserialize.
      module ToolCallResultSerializer
        # A result whose content is media (e.g. an image) is sent as a content block rather than JSON.
        #
        # @param tool_call_result [OmniAI::Chat::ToolCallResult]
        # @param context [OmniAI::Context] optional
        #
        # @return [Hash]
        def self.serialize(tool_call_result, context: nil)
          content = tool_call_result.content
          content = content.is_a?(OmniAI::Chat::Media) ? [content.serialize(context:)] : tool_call_result.text

          {
            type: "tool_result",
            tool_use_id: tool_call_result.tool_call_id,
            content:,
          }
        end

        # @param data [Hash]
        #
        # @return [OmniAI::Chat::ToolCallResult]
        def self.deserialize(data, *)
          tool_call_id = data["tool_use_id"]
          content = data["content"]

          OmniAI::Chat::ToolCallResult.new(content:, tool_call_id:)
        end
      end
    end
  end
end
