# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      # A completion returned by the API.
      class Completion < OmniAI::Chat::Completion
        # @return [Array<OmniAI::Chat::Choice>]
        def choices
          @choices ||= begin
            role = @data['role']

            @data['content'].map do |data, index|
              OmniAI::Chat::Choice.for(data: {
                'index' => index,
                'message' => { 'role' => role, 'content' => data['text'] },
              })
            end
          end
        end
      end
    end
  end
end
