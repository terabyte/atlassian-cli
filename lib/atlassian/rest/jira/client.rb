require 'atlassian/rest/client'
require 'atlassian/rest/exceptions'

module Atlassian
  module Rest
    module Jira

      class Client < Atlassian::Rest::Client

        def initialize(options)
          super(options)
        end

        def jql(query)
          # path, params, headers
          response = json_get("rest/api/2/search", {'jql' => query})
        end

      end

    end
  end
end

