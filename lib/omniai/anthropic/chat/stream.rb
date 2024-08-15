# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      # A stream given when streaming.
      class Stream < OmniAI::Chat::Stream
        module Type
          PING = 'ping'
          MESSAGE_START = 'message_start'
          MESSAGE_STOP = 'message_stop'
          MESSAGE_DELTA = 'message_delta'
          CONTENT_BLOCK_START = 'content_block_start'
          CONTENT_BLOCK_STOP = 'content_block_stop'
          CONTENT_BLOCK_DELTA = 'content_block_delta'
        end

        # Process the stream into chunks by event.
        class Builder
          # @return [OmniAI::Chat::Payload, nil]
          def payload(context:)
            return unless @content

            OmniAI::Chat::Payload.deserialize(@message.merge({
              'content' => @content,
            }), context:)
          end

          # Handler for Type::MESSAGE_START
          #
          # @param data [Hash]
          def message_start(data)
            @message = data['message']
          end

          # Handler for Type::MESSAGE_STOP
          #
          # @param _data [Hash]
          def message_stop(_data)
            @message = nil
          end

          # Handler for Type::CONTENT_BLOCK_START
          #
          # @param data [Hash]
          def content_block_start(_data)
            @content = nil
          end

          # Handler for Type::CONTENT_BLOCK_STOP
          #
          # @param _data [Hash]
          def content_block_stop(_data)
            @content = nil
          end

          # Handler for Type::CONTENT_BLOCK_DELTA
          #
          # @param data [Hash]
          def content_block_delta(data)
            @content = [{ 'type' => 'text', 'text' => data['delta']['text'] }]
          end
        end

        protected

        def builder
          @builder ||= Builder.new
        end

        # @param type [String]
        # @param data [Hash]
        # @param builder [Builder]
        def process!(type, data, id, &block)
          log(type, data, id)

          data = JSON.parse(data)

          case type
          when Type::MESSAGE_START then builder.message_start(data)
          when Type::CONTENT_BLOCK_START then builder.content_block_start(data)
          when Type::CONTENT_BLOCK_STOP then builder.content_block_stop(data)
          when Type::MESSAGE_STOP then builder.message_stop(data)
          when Type::CONTENT_BLOCK_DELTA
            builder.content_block_delta(data)

            payload = builder.payload(context: @context)
            block.call(payload) if payload
          end
        end
      end
    end
  end
end
