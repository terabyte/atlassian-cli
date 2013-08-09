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

        # https://answers.atlassian.com/questions/171351/how-to-change-the-status-of-an-issue-via-rest-api
        # and https://docs.atlassian.com/jira/REST/latest/#idp1368336
        # and a lot of perserverence =|
        def post_transition(issue, new_state, comment_text = nil)
          # get list of possible states
          @log.debug "Searching for available transitions for issue #{issue[:key]}"
          response = json_get("rest/api/2/issue/#{issue[:key]}/transitions?expand=transitions,fields")

          target_id = nil
          target_name = nil
          transition_name = nil
          response[:transitions].each do |transition|
            if transition[:name].match(Regexp.new(new_state, Regexp::IGNORECASE))
              @log.debug("Matched transition name #{transition[:name]}")
              target_id = transition[:id]
              transition_name = transition[:name]
              target_name = transition[:to][:name]
              break
            end
            if transition[:to][:name].match(Regexp.new(new_state, Regexp::IGNORECASE))
              @log.debug("Matched destination state name #{transition[:name]}")
              target_id = transition[:id]
              transition_name = transition[:name]
              target_name = transition[:to][:name]
              break
            end
          end

          if target_id.nil?
            raise Atlassian::IllegalArgumentError.new("Unable to find matching state transition for new state #{new_state}")
          end

          json = {
            :transition => {
              :id => target_id
            }
          }

          if comment_text
            json[:update] = {
              :comment => [ {
                :add => {
                  :body => comment_text
                }
              } ]
            }
          end
          response = json_post("rest/api/2/issue/#{issue[:key]}/transitions?expand=transitions,fields", json)
          @log.info "Successfully performed transition #{transition_name} on issue #{issue[:key]} from state #{issue[:fields][:status][:name]} to state #{target_name}"
        end

        # https://developer.atlassian.com/display/JIRADEV/Updating+an+Issue+via+the+JIRA+REST+APIs suggests to use the /editmeta endpoint.  IT LIES.
        def issue_update(issue, fields, comment_text = nil)

          json = {
            :update => {}
          }

          fields.keys.each do |f|
            json[:update][f] = [ { :set => fields[f] } ]
          end

          if comment_text
            json[:update][:comment] = [ {
              :add => {
                :body => comment_text
              }
            } ]
          end
          response = json_put("rest/api/2/issue/#{issue[:key]}", json)
          @log.info "Successfully updated issue #{issue[:key]}"
          response
        end
      end
    end
  end
end

