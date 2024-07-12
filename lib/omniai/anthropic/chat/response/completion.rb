# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      module Response
        # A completion returned by the API.
        class Completion < OmniAI::Chat::Response::Completion
          # @return [Array<OmniAI::Chat::Response::MessageChoice>]
          def choices
            @choices ||= begin
              role = @data['role']

              @data['content'].map do |data, index|
                OmniAI::Chat::Response::MessageChoice.new(data: {
                  'index' => index,
                  'message' => {
                    'role' => role,
                    'content' => data['text'],
                  },
                })
              end
            end
          end
        end
      end
    end
  end
end
