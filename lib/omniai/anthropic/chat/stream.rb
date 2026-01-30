# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      # Combine chunks into a hash. For each chunk yield the text (delta) if a block is given and the chunk is text.
      class Stream < OmniAI::Chat::Stream
        module Type
          MESSAGE_START = "message_start"
          MESSAGE_DELTA = "message_delta"
          MESSAGE_STOP = "message_stop"
          CONTENT_BLOCK_START = "content_block_start"
          CONTENT_BLOCK_DELTA = "content_block_delta"
          CONTENT_BLOCK_STOP = "content_block_stop"
        end

        module ContentBlockType
          TEXT = "text"
          TOOL_USE = "tool_use"
          THINKING = "thinking"
        end

        module ContentBlockDeltaType
          TEXT_DELTA = "text_delta"
          INPUT_JSON_DELTA = "input_json_delta"
          THINKING_DELTA = "thinking_delta"
          SIGNATURE_DELTA = "signature_delta"
        end

        # @yield [delta]
        # @yieldparam delta [OmniAI::Chat::Delta]
        #
        # @return [Hash]
        def stream!(&block)
          @data = { "content" => [] }

          @chunks.each do |chunk|
            parser.feed(chunk) do |type, data, id|
              process!(type, data, id, &block)
            end
          end

          @data
        end

      protected

        # @yield delta
        # @yieldparam delta [OmniAI::Chat::Delta]
        #
        # @param type [String]
        # @param data [Hash]
        # @param id [String]
        def process!(type, data, id, &)
          log(type, data, id)

          data = JSON.parse(data)

          case data["type"]
          when Type::MESSAGE_START then message_start(data)
          when Type::MESSAGE_DELTA then message_delta(data)
          when Type::MESSAGE_STOP then message_stop(data)
          when Type::CONTENT_BLOCK_START then content_block_start(data)
          when Type::CONTENT_BLOCK_DELTA then content_block_delta(data, &)
          when Type::CONTENT_BLOCK_STOP then content_block_stop(data)
          end
        end

        # Handler for Type::MESSAGE_START
        #
        # @param data [Hash]
        def message_start(data)
          @data = data["message"]
        end

        # Handler for Type::MESSAGE_DELTA
        #
        # @param data [Hash]
        def message_delta(data)
          @data.merge!(data["delta"])

          input_tokens = data.dig("usage", "input_tokens")
          output_tokens = data.dig("usage", "output_tokens")

          @data["usage"] ||= {}
          @data["usage"]["input_tokens"] = input_tokens if input_tokens
          @data["usage"]["output_tokens"] = output_tokens if output_tokens
        end

        # Handler for Type::MESSAGE_STOP
        #
        # @param _data [Hash]
        def message_stop(_data)
          # NOOP
        end

        # Handler for Type::CONTENT_BLOCK_START
        #
        # @param data [Hash]
        def content_block_start(data)
          index = data["index"]
          content_block = data["content_block"]

          # Initialize thinking content blocks with empty string for accumulation
          content_block["thinking"] = "" if content_block["type"] == ContentBlockType::THINKING

          @data["content"][index] = content_block
        end

        # Handler for Type::CONTENT_BLOCK_DELTA
        #
        # @yield [delta]
        # @yieldparam delta [OmniAI::Chat::Delta]
        #
        # @param data [Hash]
        def content_block_delta(data, &)
          case data["delta"]["type"]
          when ContentBlockDeltaType::TEXT_DELTA
            content_block_delta_for_text_delta(data, &)
          when ContentBlockDeltaType::THINKING_DELTA
            content_block_delta_for_thinking_delta(data, &)
          when ContentBlockDeltaType::INPUT_JSON_DELTA
            content_block_delta_for_input_json_delta(data, &)
          when ContentBlockDeltaType::SIGNATURE_DELTA
            content_block_delta_for_signature_delta(data)
          end
        end

        # Handler for Type::CONTENT_BLOCK_DELTA w/ ContentBlockDeltaType::TEXT_DELTA
        #
        # @yield [delta]
        # @yieldparam delta [OmniAI::Chat::Delta]
        #
        # @param data [Hash]
        def content_block_delta_for_text_delta(data, &block)
          index = data["index"]
          text = data["delta"]["text"]

          content = @data["content"][index]
          content["text"] += text

          block&.call(OmniAI::Chat::Delta.new(text:))
        end

        # Handler for Type::CONTENT_BLOCK_DELTA w/ ContentBlockDeltaType::THINKING_DELTA
        #
        # @yield [delta]
        # @yieldparam delta [OmniAI::Chat::Delta]
        #
        # @param data [Hash]
        def content_block_delta_for_thinking_delta(data, &block)
          index = data["index"]
          thinking = data["delta"]["thinking"]

          content = @data["content"][index]
          content["thinking"] += thinking

          block&.call(OmniAI::Chat::Delta.new(thinking:))
        end

        # Handler for Type::CONTENT_BLOCK_DELTA w/ ContentBlockDeltaType::INPUT_JSON_DELTA
        #
        # @yield [delta]
        # @yieldparam delta [OmniAI::Chat::Delta]
        #
        # @param data [Hash]
        def content_block_delta_for_input_json_delta(data)
          content = @data["content"][data["index"]]
          content["partial_json"] ||= ""
          content["partial_json"] += data["delta"]["partial_json"]
        end

        # Handler for Type::CONTENT_BLOCK_DELTA w/ ContentBlockDeltaType::SIGNATURE_DELTA
        #
        # @param data [Hash]
        def content_block_delta_for_signature_delta(data)
          content = @data["content"][data["index"]]
          content["signature"] ||= ""
          content["signature"] += data["delta"]["signature"]
        end

        # Handler for Type::CONTENT_BLOCK_STOP
        #
        # @param data [Hash]
        def content_block_stop(data)
          index = data["index"]
          content = @data["content"][index]

          # Capture signature for thinking blocks (required for tool call round-trips)
          signature = data.dig("content_block", "signature")
          content["signature"] = signature if content["type"] == ContentBlockType::THINKING && signature

          # Handle partial JSON for tool use blocks
          return unless content["partial_json"]
          return if content["partial_json"].empty?

          content["input"] = JSON.parse(content["partial_json"])
          content.delete("partial_json")
        end
      end
    end
  end
end
