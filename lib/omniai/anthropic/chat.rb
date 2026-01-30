# frozen_string_literal: true

module OmniAI
  module Anthropic
    # An Anthropic chat implementation.
    #
    # Usage:
    #
    #   completion = OmniAI::Anthropic::Chat.process!(client: client) do |prompt|
    #     prompt.system('You are an expert in the field of AI.')
    #     prompt.user('What are the biggest risks of AI?')
    #   end
    #   completion.text # '...'
    class Chat < OmniAI::Chat
      module Model
        CLAUDE_INSTANT_1_0 = "claude-instant-1.2"
        CLAUDE_2_0 = "claude-2.0"
        CLAUDE_2_1 = "claude-2.1"

        CLAUDE_3_HAIKU_20240307 = "claude-3-haiku-20240307"
        CLAUDE_3_5_HAIKU_20241022 = "claude-3-5-haiku-20241022"
        CLAUDE_HAIKU_4_5_20251001 = "claude-haiku-4-5-20251001"
        CLAUDE_3_OPUS_20240229 = "claude-3-opus-20240229"
        CLAUDE_3_SONNET_20240209 = "claude-3-sonnet-20240229"
        CLAUDE_3_SONNET_20240307 = "claude-3-sonnet-20240307"
        CLAUDE_3_5_SONNET_20240620 = "claude-3-5-sonnet-20240620"
        CLAUDE_3_5_SONNET_20241022 = "claude-3-5-sonnet-20241022"
        CLAUDE_3_7_SONNET_20250219 = "claude-3-7-sonnet-20250219"

        CLAUDE_3_5_HAIKU_LATEST = "claude-3-5-haiku-latest"
        CLAUDE_3_OPUS_LATEST = "claude-3-opus-latest"
        CLAUDE_3_5_SONNET_LATEST = "claude-3-5-sonnet-latest"
        CLAUDE_3_7_SONNET_LATEST = "claude-3-7-sonnet-latest"

        CLAUDE_OPUS_4_20250514 = "claude-opus-4-20250514"
        CLAUDE_OPUS_4_1_20250805 = "claude-opus-4-1-20250805"
        CLAUDE_OPUS_4_5_20251101 = "claude-opus-4-5-20251101"
        CLAUDE_SONNET_4_20250514 = "claude-sonnet-4-20250514"
        CLAUDE_SONNET_4_5_20240620 = "claude-sonnet-4-5-20250929"

        CLAUDE_HAIKU_4_5 = "claude-haiku-4-5"
        CLAUDE_OPUS_4_0 = "claude-opus-4-0"
        CLAUDE_OPUS_4_1 = "claude-opus-4-1"
        CLAUDE_OPUS_4_5 = "claude-opus-4-5"
        CLAUDE_SONNET_4_0 = "claude-sonnet-4-0"
        CLAUDE_SONNET_4_5 = "claude-sonnet-4-5"

        CLAUDE_HAIKU = CLAUDE_HAIKU_4_5
        CLAUDE_OPUS = CLAUDE_OPUS_4_5
        CLAUDE_SONNET = CLAUDE_SONNET_4_5
      end

      DEFAULT_MODEL = Model::CLAUDE_SONNET

      # @return [Context]
      CONTEXT = Context.build do |context|
        context.serializers[:tool] = ToolSerializer.method(:serialize)

        context.serializers[:file] = FileSerializer.method(:serialize)
        context.serializers[:url] = URLSerializer.method(:serialize)

        context.serializers[:choice] = ChoiceSerializer.method(:serialize)
        context.deserializers[:choice] = ChoiceSerializer.method(:deserialize)

        context.serializers[:tool_call] = ToolCallSerializer.method(:serialize)
        context.deserializers[:tool_call] = ToolCallSerializer.method(:deserialize)

        context.serializers[:tool_call_result] = ToolCallResultSerializer.method(:serialize)
        context.deserializers[:tool_call_result] = ToolCallResultSerializer.method(:deserialize)

        context.serializers[:function] = FunctionSerializer.method(:serialize)
        context.deserializers[:function] = FunctionSerializer.method(:deserialize)

        context.serializers[:message] = MessageSerializer.method(:serialize)
        context.deserializers[:message] = MessageSerializer.method(:deserialize)

        context.deserializers[:content] = ContentSerializer.method(:deserialize)
        context.deserializers[:response] = ResponseSerializer.method(:deserialize)

        context.serializers[:thinking] = ThinkingSerializer.method(:serialize)
        context.deserializers[:thinking] = ThinkingSerializer.method(:deserialize)
      end

      # @return [Hash]
      def payload
        data = OmniAI::Anthropic.config.chat_options.merge({
          model: @model,
          messages:,
          system:,
          stream: stream? || nil,
          temperature: thinking_config ? nil : @temperature, # Anthropic requires temperature=1 (default) when thinking
          tools: tools_payload,
          thinking: thinking_config,
        }).compact

        # When thinking is enabled, ensure max_tokens > budget_tokens
        data[:max_tokens] = thinking_max_tokens if thinking_config

        data
      end

      # Translates unified thinking option to Anthropic's native format.
      # Example: `thinking: { budget_tokens: 10000 }` becomes `{ type: "enabled", budget_tokens: 10000 }`
      # @return [Hash, nil]
      def thinking_config
        thinking = @options[:thinking]
        return unless thinking

        case thinking
        when true then { type: "enabled", budget_tokens: 10_000 }
        when Hash then { type: "enabled" }.merge(thinking)
        end
      end

      # Returns max_tokens ensuring it's greater than budget_tokens when thinking is enabled.
      # @return [Integer]
      def thinking_max_tokens
        budget = thinking_config[:budget_tokens]
        base = @options[:max_tokens] || OmniAI::Anthropic.config.chat_options[:max_tokens] || 0
        # Ensure max_tokens > budget_tokens (default to budget + 8000 for response)
        [base, budget + 8_000].max
      end

      # @return [Array<Hash>]
      def messages
        messages = @prompt.messages.reject(&:system?)
        messages.map { |message| message.serialize(context:) }
      end

      # @return [String, nil]
      def system
        parts = @prompt.messages.filter(&:system?).filter(&:text?).map(&:text)
        parts << formatting if formatting?
        return if parts.empty?

        parts.join("\n\n")
      end

      # @return [String]
      def path
        "/#{Client::VERSION}/messages"
      end

    protected

      # @return [Context]
      def context
        CONTEXT
      end

      # @return [Array<Message>]
      def build_tool_call_messages(tool_call_list)
        content = tool_call_list.map do |tool_call|
          ToolCallResult.new(tool_call_id: tool_call.id, content: execute_tool_call(tool_call))
        end

        [Message.new(role: OmniAI::Chat::Role::USER, content:)]
      end

    private

      # @return [Boolean]
      def formatting?
        !@format.nil?
      end

      # @return [String, nil]
      def formatting
        case @format
        when OmniAI::Schema::Format then @format.prompt
        when :text then "You must respond with TEXT."
        when :json then "You must respond with JSON."
        end
      end

      # @return [Array<Hash>, nil]
      def tools_payload
        @tools.map { |tool| tool.serialize(context:) } if @tools&.any?
      end
    end
  end
end
