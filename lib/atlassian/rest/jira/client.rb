require 'andand'

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

        def get_issue_by_id(id)
          response = json_get("rest/api/2/search", {'jql' => "id = #{id}"})
          return response[:issues].andand.first
        end

        def get_issue_by_key(key)
          response = json_get("rest/api/2/search", {'jql' => "key = #{key}"})
          return response[:issues].andand.first
        end
      end

    end
  end
end

