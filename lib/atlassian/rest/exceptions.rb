require 'atlassian/exceptions'

module Atlassian
  module Rest

    class AtlassianRestError < AtlassianError
    end

    class AuthenticationError < AtlassianRestError
    end

    class InternalServerError < AtlassianRestError
    end

    class ClientError < AtlassianRestError
    end
  end
end

