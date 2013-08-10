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
        def issue_update(issue, edit_opts = {})

          json = {
            :update => {}
          }

          edit_opts[:fields].keys.each do |f|
            json[:update][f] = [ { :set => edit_opts[:fields][f] } ]
          end

          if edit_opts[:commentText]
            json[:update][:comment] = [ {
              :add => {
                :body => edit_opts[:commentText]
              }
            } ]
          end

          # If we are updating priority, need to fetch its ID
          if edit_opts[:priority]
            priorities = json_get("rest/api/2/priority")
            priority_name = nil
            priority_id = nil
            priorities.each do |p|
              if p[:name].match(Regexp.new(edit_opts[:priority], Regexp::IGNORECASE))
                @log.debug("Matched priority name #{p[:name]}")
                priority_name = p[:name]
                priority_id = p[:id]
                break
              end
            end
            if priority_name.nil?
              @log.error "Unable to find priority for #{edit_opts[:priority]}, ignoring!"
            else
              json[:update][:priority] = [ { :set => {:id => priority_id} } ]
            end
          end

          # If we are updating components, need to fetch the possibilities
          if !edit_opts[:components].empty?
            # create the container
            json[:update][:components] = []
            components = json_get("rest/api/2/project/#{issue[:fields][:project][:key]}/components")

            # for each component, figure out if we are adding or removing and match to an ID
            edit_opts[:components].each do |current_component|
              operation = :add
              current_component.gsub!(/^\+/, '')
              if current_component.match(/^-/)
                operation = :remove
                current_component.gsub!(/^-/, '')
              end

              found = false
              components.each do |c|
                if c[:name].match(Regexp.new(current_component, Regexp::IGNORECASE))
                  @log.debug("Matched component #{operation} => #{c[:name]} for regex #{current_component}")
                  json[:update][:components] << { operation => { :id => c[:id] } }
                  found = true
                  break
                end
              end
              if !found
                @log.error "Unable to find component for #{current_component}, ignoring!"
              end
            end
          end

          # If we are updating fixversions, need to fetch the possibilities
          if !edit_opts[:fixversions].empty?
            # create the container
            # ARGH!  the key "fixVersions" isn't listed in the editmeta API
            # call output...but it works (as of jira 5.2.11 anyways).  and YES,
            # it is case senstiive.  awesome.
            json[:update][:fixVersions] = []
            fixversions = json_get("rest/api/2/project/#{issue[:fields][:project][:key]}/versions")

            # for each fixversion, figure out if we are adding or removing and match to an ID
            edit_opts[:fixversions].each do |current_fixversion|
              operation = :add
              current_fixversion.gsub!(/^\+/, '')
              if current_fixversion.match(/^-/)
                operation = :remove
                current_fixversion.gsub!(/^-/, '')
              end

              found = false
              fixversions.each do |f|
                if f[:name].match(Regexp.new(current_fixversion, Regexp::IGNORECASE))
                  @log.debug("Matched fixversion #{operation} => #{f[:name]} for regex #{current_fixversion}")
                  json[:update][:fixVersions] << { operation => { :id => f[:id] } }
                  found = true
                  break
                end
              end
              if !found
                @log.error "Unable to find fixversion for #{current_fixversion}, ignoring!"
              end
            end
          end

          # If we are updating affectsversions, need to fetch the possibilities
          if !edit_opts[:affectsversions].empty?
            # create the container
            json[:update][:versions] = []
            affectsversions = json_get("rest/api/2/project/#{issue[:fields][:project][:key]}/versions")

            # for each affectsversion, figure out if we are adding or removing and match to an ID
            edit_opts[:affectsversions].each do |current_affectsversion|
              operation = :add
              current_affectsversion.gsub!(/^\+/, '')
              if current_affectsversion.match(/^-/)
                operation = :remove
                current_affectsversion.gsub!(/^-/, '')
              end

              found = false
              affectsversions.each do |f|
                if f[:name].match(Regexp.new(current_affectsversion, Regexp::IGNORECASE))
                  @log.debug("Matched affectsversion #{operation} => #{f[:name]} for regex #{current_affectsversion}")
                  json[:update][:versions] << { operation => { :id => f[:id] } }
                  found = true
                  break
                end
              end
              if !found
                @log.error "Unable to find affectsversion for #{current_affectsversion}, ignoring!"
              end
            end
          end

          if edit_opts[:assignee]
            # get the list of assignable people for this issue
            assignees = json_get("rest/api/2/user/assignable/search?issueKey=#{issue[:key]}&maxResults=2&username=#{URI.escape(edit_opts[:assignee])}")

            if (assignees.size != 1)
              @log.error "Unable to find UNIQUE assignee for #{edit_opts[:assignee]}, ignoring (try a larger substring, check spelling?)"
              @log.error "Candidates: " + assignees.map {|x| x[:name] }.join(", ")
            else
              json[:update][:assignee] = [{ :set => { :name => assignees.first[:name] } } ]
            end
          end

          response = json_put("rest/api/2/issue/#{issue[:key]}", json)
          @log.info "Successfully updated issue #{issue[:key]}"
          response
        end
      end
    end
  end
end

