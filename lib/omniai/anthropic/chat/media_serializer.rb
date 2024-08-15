# frozen_string_literal: true

module OmniAI
  module Anthropic
    class Chat
      # Overrides media serialize / deserialize.
      module MediaSerializer
        # @param payload [OmniAI::Chat::Media]
        # @return [Hash]
        def self.serialize(media, *)
          {
            type: media.kind, # i.e. 'image' / 'video' / 'audio' / ...
            source: {
              type: 'base64',
              media_type: media.type, # i.e. 'image/jpeg' / 'video/ogg' / 'audio/mpeg' / ...
              data: media.data,
            },
          }
        end
      end
    end
  end
end
