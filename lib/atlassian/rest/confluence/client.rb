require 'andand'

require 'atlassian/rest/client'
require 'atlassian/rest/exceptions'

module Atlassian
  module Rest
    module Confluence

      class Client < Atlassian::Rest::Client

        attr_accessor :auth_success

        def initialize(options)
          super(options)

          @auth_success = nil
        end

        def get_page_by_id(id)
          # always ensure we are logged in first
          ensure_logged_in

          # path, params, headers
          # http://cmyers-ubuntu.dyn.yojoe.local:1990/confluence/rest/prototype/latest/content/819244
          response = json_get("rest/prototype/latest/content/#{id}")
        end

        def test_auth()
          unless @auth_success.nil?
            return @auth_success
          end

          response = raw_get(@endpoint + "rest/prototype/latest/session")
          if response.status.to_i == 200
            @auth_success = true
            return true
          end
          return false
        end
      end
    end
  end
end

