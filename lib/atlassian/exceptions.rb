
module Atlassian
  class AtlassianError < Exception
  end

  class IllegalArgumentError < AtlassianError
  end

  class NotFoundError < AtlassianError
  end
end

