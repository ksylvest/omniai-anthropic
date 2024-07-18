# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      module Response
        # A stream given when streaming.
        class Stream < OmniAI::Chat::Response::Stream
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
            attr_reader :id, :model, :role, :content, :index

            # @return [OmniAI::Chat::Chunk]
            def chunk
              OmniAI::Chat::Response::Chunk.new(data: {
                'id' => @id,
                'model' => @model,
                'choices' => [{
                  'index' => @index,
                  'delta' => {
                    'role' => @role,
                    'content' => @content,
                  },
                }],
              })
            end

            # Handler for Type::MESSAGE_START
            #
            # @param data [Hash]
            def message_start(data)
              @id = data['id']
              @model = data['model']
              @role = data['role']
            end

            # Handler for Type::MESSAGE_STOP
            #
            # @param _data [Hash]
            def message_stop(_data)
              @id = nil
              @model = nil
              @role = nil
            end

            # Handler for Type::CONTENT_BLOCK_START
            #
            # @param data [Hash]
            def content_block_start(data)
              @index = data['index']
            end

            # Handler for Type::CONTENT_BLOCK_STOP
            #
            # @param _data [Hash]
            def content_block_stop(_data)
              @index = nil
            end

            # Handler for Type::CONTENT_BLOCK_DELTA
            #
            # @param data [Hash]
            def content_block_delta(data)
              return unless data['delta']['type'].eql?('text_delta')

              @content = data['delta']['text']
            end
          end

          # @yield [OmniAI::Chat::Chunk]
          def stream!(&block)
            builder = Builder.new

            @response.body.each do |chunk|
              @parser.feed(chunk) do |type, data|
                process(type:, data: JSON.parse(data), builder:, &block)
              end
            end
          end

          private

          # @param type [String]
          # @param data [Hash]
          # @param builder [Builder]
          def process(type:, data:, builder:, &)
            case type
            when Type::MESSAGE_START then builder.message_start(data)
            when Type::CONTENT_BLOCK_START then builder.content_block_start(data)
            when Type::CONTENT_BLOCK_STOP then builder.content_block_stop(data)
            when Type::MESSAGE_STOP then builder.message_stop(data)
            when Type::CONTENT_BLOCK_DELTA
              builder.content_block_delta(data)
              yield(builder.chunk)
            end
          end
        end
      end
    end
  end
end
