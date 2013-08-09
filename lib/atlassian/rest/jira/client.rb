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

        # https://developer.atlassian.com/display/JIRADEV/JIRA+REST+API+Example+-+Add+Comment
        def get_comments_for_issue(issue)
          response = json_get("rest/api/2/issue/#{issue[:key]}/comment")
          return response
        end

        def post_comment_for_issue(issue, comment)
          response = json_post("rest/api/2/issue/#{issue[:key]}/comment", comment)
          return response
        end

      end
    end
  end
end

