module Atlassian
  module Rest

    class AtlassianRestError < Exception
    end

    class AuthenticationError < AtlassianRestError
    end

    class InternalServerError < AtlassianRestError
    end

    class ClientError < AtlassianRestError
    end
  end
end

