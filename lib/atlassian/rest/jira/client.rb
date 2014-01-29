require 'andand'

require 'atlassian/rest/client'
require 'atlassian/rest/exceptions'

module Atlassian
  module Rest
    module Jira

      class Client < Atlassian::Rest::Client

        attr_accessor :auth_success
        attr_accessor :api_version

        def initialize(options)
          super(options)

          @auth_success = nil
          @api_version = 2
        end

        def jql(query)
          # always ensure we are logged in first
          ensure_logged_in

          # path, params, headers
          response = json_get("rest/api/#{@api_version}/search", {'jql' => query, :fields => "*all,-comment"})
        end

        def get_issue_by_id(id)
          # always ensure we are logged in first
          ensure_logged_in

          response = json_get("rest/api/#{@api_version}/issue/#{id}", {:fields => "*all,-comment"})
          return response
        end

        def get_issue_by_key(key)
          # always ensure we are logged in first
          ensure_logged_in

          response = json_get("rest/api/#{@api_version}/issue/#{key}", {:fields => "*all,-comment"})
          return response
        end

        # https://developer.atlassian.com/display/JIRADEV/JIRA+REST+API+Example+-+Add+Comment
        def get_comments_for_issue(issue)
          # always ensure we are logged in first
          ensure_logged_in

          response = json_get("rest/api/#{@api_version}/issue/#{issue[:key]}/comment")
          return response
        end

        def post_comment_for_issue(issue, comment)
          # always ensure we are logged in first
          ensure_logged_in

          response = json_post("rest/api/#{@api_version}/issue/#{issue[:key]}/comment", comment)
          return response
        end

        # https://answers.atlassian.com/questions/171351/how-to-change-the-status-of-an-issue-via-rest-api
        # and https://docs.atlassian.com/jira/REST/latest/#idp1368336
        # and a lot of perserverence =|
        def post_transition(issue, new_state, comment_text = nil, resolution_regex = nil)
          # always ensure we are logged in first
          ensure_logged_in

          # get list of possible states
          @log.debug "Searching for available transitions for issue #{issue[:key]}"
          response = json_get("rest/api/#{@api_version}/issue/#{issue[:key]}/transitions?expand=transitions,fields")

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

          # If provided we need to set the resolution, otherwise we can leave it out
          if resolution_regex
            resolution = get_matching_object_by_regex("rest/api/#{@api_version}/resolution", Regexp.new(resolution_regex, Regexp::IGNORECASE))

            if resolution[0].nil?
              @log.error "Unable to find resolution for #{opts[:priority]}, ignoring!"
            else
              json[:fields] = {
                  :resolution => {
                    :id => resolution[0]
                }
              }
            end
          end

          response = json_post("rest/api/#{@api_version}/issue/#{issue[:key]}/transitions?expand=transitions,fields", json)
          @log.info "Successfully performed transition #{transition_name} on issue #{issue[:key]} from state #{issue[:fields][:status][:name]} to state #{target_name}"
        end

        # https://developer.atlassian.com/display/JIRADEV/Updating+an+Issue+via+the+JIRA+REST+APIs suggests to use the /editmeta endpoint.  IT LIES.
        def issue_update(issue, edit_opts = {})
          # always ensure we are logged in first
          ensure_logged_in


          json = {
            :update => {}
          }

          edit_opts[:fields].keys.each do |f|
            json[:update][f] = [ { :set => edit_opts[:fields][f] } ]
          end

          edit_opts[:customfields].andand.each_pair do |n,cf|
            json[:fields][n] = cf
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
            priorities = json_get("rest/api/#{@api_version}/priority")
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
          if !edit_opts[:components].andand.empty?
            # create the container
            json[:update][:components] = []
            components = json_get("rest/api/#{@api_version}/project/#{issue[:fields][:project][:key]}/components")

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

          # If we are updating issuetype, need to fetch the possibilities
          if !edit_opts[:issuetype].andand.empty?
            found_issue_type = nil
            match = false
            issuetypes = json_get("rest/api/#{@api_version}/issue/createmeta?projectKeys=#{issue[:fields][:project][:key]}")[:projects].first[:issuetypes]
            issuetypes.sort {|a,b| a[:id].to_i <=> b[:id].to_i }.each do |issuetype|
              @log.debug "Found issuetype: #{issuetype[:name]}"

              if issuetype[:name].match(Regexp.new(edit_opts[:issuetype] || ".", Regexp::IGNORECASE))
                found_issue_type = issuetype
                match = true
                break
              end
            end

            if match
              json[:fields] = {} if json[:fields].nil?
              json[:fields][:issuetype] = { :id => found_issue_type[:id] }
              # XXX: Note that if the issue was a non-sub-task and we are
              # converting to a sub-task type, the call will fail (with a very
              # unhelpful error message "Issue type is a sub-task but parent
              # issue key or id not specified.").  This is because the REST API
              # does not support this.  See:
              # https://jira.atlassian.com/browse/JRA-27893
              # Leaving this stuff in here anyways in case they ever fix it,
              # and also so we can re-parent existing subtasks, or switch
              # between two issue types where both are subtask or non-subtask.
              @log.debug("Matched issue type #{found_issue_type[:name]} with regex #{edit_opts[:issuetype]}")
              if !edit_opts[:parent].nil?
                @log.debug("Including parent key #{edit_opts[:parent]}")
                json[:fields][:parent] = { :key => edit_opts[:parent] }
              end
            else
              raise Atlassian::IllegalArgumentError.new("Unable to find matching issue type for regex #{edit_opts[:issuetype]}")
            end
          end

          # If we are updating fixversions, need to fetch the possibilities
          if !edit_opts[:fixversions].andand.empty?
            # create the container
            # ARGH!  the key "fixVersions" isn't listed in the editmeta API
            # call output...but it works (as of jira 5.2.11 anyways).  and YES,
            # it is case senstiive.  awesome.
            json[:update][:fixVersions] = []
            fixversions = json_get("rest/api/#{@api_version}/project/#{issue[:fields][:project][:key]}/versions")

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
          if !edit_opts[:affectsversions].andand.empty?
            # create the container
            json[:update][:versions] = []
            affectsversions = json_get("rest/api/#{@api_version}/project/#{issue[:fields][:project][:key]}/versions")

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
            assignees = json_get("rest/api/#{@api_version}/user/assignable/search?issueKey=#{issue[:key]}&maxResults=2&username=#{URI.escape(edit_opts[:assignee])}")

            if (assignees.size != 1)
              @log.error "Unable to find UNIQUE assignee for #{edit_opts[:assignee]}, ignoring (try a larger substring, check spelling?)"
              @log.error "Candidates: " + assignees.map {|x| x[:name] }.join(", ")
            else
              json[:update][:assignee] = [{ :set => { :name => assignees.first[:name] } } ]
            end
          end

          response = json_put("rest/api/#{@api_version}/issue/#{issue[:key]}", json)
          @log.info "Successfully updated issue #{issue[:key]}"
          response
        end

        def issue_create(opts)
          # always ensure we are logged in first
          ensure_logged_in

          @log.debug "Creating issue with arguments #{opts}"

          json = {
            :fields => opts[:fields],
          }

          opts[:customfields].each_pair do |n,cf|
            json[:fields][n] = cf
          end

          # DEVS: use this to get the create meta for all projects
          #createmeta = json_get("rest/api/#{@api_version}/issue/createmeta")
          #ap createmeta
          #exit 1

          # TODO: allow regex here to find a project by name?
          # seems unnecessary, keys are short and generally known.
          json[:fields][:project] = { :key => opts[:projectkey] }

          # We need to determine an issue type.  I thought there was such a
          # thing as default issue type but I don't see that here, so we will
          # use the type with the lowest ID that isn't a subissue type unless a
          # regex is provided.  People could add a default type to their RC file.
          createmeta = json_get("rest/api/#{@api_version}/issue/createmeta?projectKeys=#{opts[:projectkey]}")
          #ap createmeta
          #exit 1

          if createmeta[:projects].empty?
            raise Atlassian::IllegalArgumentError.new("No projects found for key #{opts[:projectkey]}")
          end

          @log.debug("ISSUE TYPE: #{opts[:issuetype]}")
          found_issue_type = nil
          match = false
          createmeta[:projects].first[:issuetypes].sort {|a,b| a[:id].to_i <=> b[:id].to_i }.each do |type|
            next if opts[:parent].nil? && type[:subtask]

            @log.debug "Found issuetype: #{type[:name]}"
            if found_issue_type.nil? || (found_issue_type && found_issue_type[:id] > type[:id])
              found_issue_type = type
            end

            if type[:name].match(Regexp.new(opts[:issuetype] || ".", Regexp::IGNORECASE))
              found_issue_type = type
              match = true
              break
            end
          end

          json[:fields][:issuetype] = { :id => found_issue_type[:id] }
          if found_issue_type[:subtask]
            json[:fields][:parent] = { :key => opts[:parent] }
          end
          if match
            @log.debug("Matched issue type #{found_issue_type[:name]} with regex #{opts[:issuetype]}")
          else
            @log.debug("Using default issue type #{found_issue_type[:name]} regex #{opts[:issuetype]}")
          end

          # If provided we need to set the priority, otherwise we can leave it out
          if opts[:priority]
            priority = get_matching_object_by_regex("rest/api/#{@api_version}/priority", Regexp.new(opts[:priority], Regexp::IGNORECASE))

            if priority[0].nil?
              @log.error "Unable to find priority for #{opts[:priority]}, ignoring!"
            else
              json[:fields][:priority] = { :id => priority[0]}
            end
          end

          # If we are settings components, need to fetch the possibilities
          if opts[:components] && !opts[:components].empty?
            # create the container
            json[:fields][:components] = []
            components = json_get("rest/api/#{@api_version}/project/#{opts[:projectkey]}/components")

            # for each component, figure out if we are adding or removing and match to an ID
            opts[:components].each do |current_component|
              json[:fields][:components] = []
              # doesn't make sense to remove component from new issue, always add
              current_component.gsub!(/^\+/, '')
              current_component.gsub!(/^-/, '')

              found = false
              components.each do |c|
                if c[:name].match(Regexp.new(current_component, Regexp::IGNORECASE))
                  @log.debug("Matched component #{c[:name]} for regex #{current_component}")
                  json[:fields][:components] << { :id => c[:id] }
                  found = true
                  break
                end
              end
              if !found
                @log.error "Unable to find component for #{current_component}, ignoring!"
              end
            end
          end

          # If we are setting fixversions, need to fetch the possibilities
          if opts[:fixversions] && !opts[:fixversions].empty?
            json[:fields][:fixVersions] = []
            fixversions = json_get("rest/api/#{@api_version}/project/#{opts[:projectkey]}/versions")

            opts[:fixversions].each do |current_fixversion|
              current_fixversion.gsub!(/^\+/, '')
              current_fixversion.gsub!(/^-/, '')

              found = false
              fixversions.each do |f|
                if f[:name].match(Regexp.new(current_fixversion, Regexp::IGNORECASE))
                  @log.debug("Matched fixversion #{f[:name]} for regex #{current_fixversion}")
                  json[:fields][:fixVersions] << { :id => f[:id] }
                  found = true
                  break
                end
              end
              if !found
                @log.error "Unable to find fixversion for #{current_fixversion}, ignoring!"
              end
            end
          end

          # If we are setting affectsversions, need to fetch the possibilities
          # TODO: why doesn't this work?
          if false && opts[:affectsversions] && !opts[:affectsversions].empty?
            json[:fields][:affectsVersions] = []
            # TODO: only call this once?  Also, fix the issue_update method the same way
            affectsversions = json_get("rest/api/#{@api_version}/project/#{opts[:projectkey]}/versions")

            opts[:affectsversions].each do |current_affectsversion|
              current_affectsversion.gsub!(/^\+/, '')
              current_affectsversion.gsub!(/^-/, '')

              found = false
              affectsversions.each do |f|
                if f[:name].match(Regexp.new(current_affectsversion, Regexp::IGNORECASE))
                  @log.debug("Matched affectsversion #{f[:name]} for regex #{current_affectsversion}")
                  json[:fields][:affectsVersions] << { :id => f[:id] }
                  found = true
                  break
                end
              end
              if !found
                @log.error "Unable to find affectsversion for #{current_affectsversion}, ignoring!"
              end
            end
          end

          if opts[:assignee]
            # get the list of assignable people for this issue
            assignees = json_get("rest/api/#{@api_version}/user/assignable/search?project=#{opts[:projectkey]}&maxResults=2&username=#{URI.escape(opts[:assignee])}")

            if (assignees.size != 1)
              @log.error "Unable to find UNIQUE assignee for #{opts[:assignee]}, ignoring (try a larger substring, check spelling?)"
              @log.error "Candidates: " + assignees.map {|x| x[:name] }.join(", ")
            else
              json[:fields][:assignee] = { :name => assignees.first[:name] }
            end
          end

          response = json_post("rest/api/#{@api_version}/issue", json)
          if response[:key]
            @log.info "Successfully created issue #{response[:key]}"
          else
            @log.error "Unable to create issue"
          end
          response
        end

        def issue_link_create(opts)
          # always ensure we are logged in first
          ensure_logged_in

          @log.debug "Creating issue link with arguments #{opts}"

          types = json_get("rest/api/#{@api_version}/issueLinkType")[:issueLinkTypes]

          json = {
            :inwardIssue => { :key => opts[:inwardIssueKey] },
            :outwardIssue => { :key => opts[:outwardIssueKey] },
          }

          if opts[:commentText]
            json[:comment] = { :body => opts[:commentText] }
          end

          # figure out link type
          linktype = nil
          types.each do |type|
            if type[:name].match(Regexp.new(opts[:linktype], Regexp::IGNORECASE))
              @log.debug "Found issue type #{type[:name]}"
              linktype = type
              break
            end
          end
          if linktype.nil?
            raise Atlassian::IllegalArgumentError.new("No links found that match the regex #{opts[:linktype]}")
          end

          json[:type] = { :id => linktype[:id] }

          response = json_post("rest/api/#{@api_version}/issueLink", json)

          @log.info "Successfully created issue link #{opts[:outwardIssueKey]} #{linktype[:inward]} #{opts[:inwardIssueKey]}"
        end

        def issue_link_delete(opts)
          # always ensure we are logged in first
          ensure_logged_in

          @log.debug "Deleting issue link with arguments #{opts}"

          # get from-issue
          issue = get_issue_by_id(opts[:inwardIssueKey])

          issue[:fields][:issuelinks].andand.each do |link|
            next unless link[:type][:name].match(Regexp.new(opts[:linktype], Regexp::IGNORECASE))
            next unless link[:outwardIssue][:key] == opts[:outwardIssueKey]

            @log.debug "Found issue link to delete: #{link.inspect}"

            response = json_delete("rest/api/#{@api_version}/issueLink/#{link[:id]}")
            return
          end

          # if we get here, we couldn't find a link to delete
          raise Atlassian::IllegalArgumentError.new("No links found that match the regex '#{opts[:linktype]}' for issue #{opts[:outwardIssueKey]} to issue #{opts[:inwardIssueKey]}")
        end

        def attachment_create(id_or_key, opts)
          # always ensure we are logged in first
          ensure_logged_in

          @log.debug "Creating attachment for issue #{id_or_key} with arguments #{opts}"

          response = nil
          File.open(opts[:path]) do |file|
            params = { :file => file }
            response = json_post_file("rest/api/#{@api_version}/issue/#{id_or_key}/attachments", file, {'X-Atlassian-Token' => 'nocheck'})
            if opts[:debug]
              ap response
            end
          end
          at = response.first
          @log.info "Successfully created attachment #{at[:filename]} with id #{at[:id]} size #{at[:size]} mimetype #{at[:mimeType]}"
        end

        def attachment_delete(attachment_id, opts)
          # always ensure we are logged in first
          ensure_logged_in

          response = json_delete("rest/api/#{@api_version}/attachment/#{attachment_id}")
          if opts[:debug]
            ap response
          end
        end

        def attachment_delete_by_issue_and_filename(issue_id_or_key, filename, opts)
          # always ensure we are logged in first
          ensure_logged_in

          @log.debug "Deleting all attachment for issue #{issue_id_or_key} with filename matching #{filename}"

          issue = nil
          if issue_id_or_key.match(/^\d+$/)
            issue = get_issue_by_id(issue_id_or_key)
          else
            # already raises in case of error
            issue = get_issue_by_key(issue_id_or_key)
          end

          issue[:fields][:attachment].each do |at|
            next unless at[:filename].match(filename)

            @log.info "Found attachment id #{at[:id]}, deleting"
            response = json_delete("rest/api/#{@api_version}/attachment/#{at[:id]}")
            if opts[:debug]
              ap response
            end
          end
        end

        def attachment_download_by_issue_and_filename(issue_id_or_key, filename, opts)
          # always ensure we are logged in first
          ensure_logged_in

          @log.debug "Downloading attachment for issue #{issue_id_or_key} with filename matching #{filename}"

          issue = nil
          if issue_id_or_key.match(/^\d+$/)
            issue = get_issue_by_id(issue_id_or_key)
          else
            # already raises in case of error
            issue = get_issue_by_key(issue_id_or_key)
          end

          issue[:fields][:attachment].each do |at|
            next unless at[:filename].match(filename)

            @log.info "Found attachment id #{at[:id]} filename #{at[:filename]}, downloading"
            # in atlas-cli specifically, we require path because PWD is always
            # set to the atlas-cli directory when invoking the CLI using the
            # standard method, which is fairly unhelpful.  Nonetheless, for
            # clients invoked in a different way, we might as well do this
            # fallback code.
            path = opts[:path] || File.join(Dir.pwd, attachment[:filename])

            file_get(at[:content], path)
            # return because we grab the first one matching the filename
            return
          end
          raise Atlassian::IllegalArgumentError.new("No attachment found that match the filename '#{filename}' for issue #{issue_id_or_key}")
        end

        def attachment_download(attachment_id, opts)
          # always ensure we are logged in first
          ensure_logged_in

          @log.debug "Downloading attachment id #{attachment_id}"

          attachment = json_get("rest/api/#{@api_version}/attachment/#{attachment_id}")

          @log.info "Found attachment id #{attachment_id} filename #{attachment[:filename]}, downloading"

          # in atlas-cli specifically, we require path because PWD is always
          # set to the atlas-cli directory when invoking the CLI using the
          # standard method, which is fairly unhelpful.  Nonetheless, for
          # clients invoked in a different way, we might as well do this
          # fallback code.
          path = opts[:path] || File.join(Dir.pwd, attachment[:filename])

          file_get(attachment[:content], path)
        end

        def issue_delete(key)
          # always ensure we are logged in first
          ensure_logged_in

          @log.debug "Deleting issue #{key}"

          response = json_delete("rest/api/#{@api_version}/issue/#{key}")
          @log.info "Successfully deleted issue #{key}"
          response
        end

        def component_get(project_or_issue_key, opts)
          # always ensure we are logged in first
          ensure_logged_in

          @log.debug "Getting components for issue/project #{project_or_issue_key}"

          response = json_get("/rest/api/#{@api_version}/project/#{project_or_issue_key}/components")
          if opts[:debug]
            ap response
          end
          return response
        end

        # TODO: http://localhost:2990/jira/rest/api/#{@api_version}/resolution
        # Returns [id, name] for first match found
        def get_matching_object_by_regex(url, regex)
          items = json_get(url)
          item_name = nil
          item_id = nil
          # sort so we always find the same one, lowest ID first
          items.sort {|a,b| a[:id].to_i <=> b[:id].to_i}.each do |p|
            if p[:name].match(regex)
              @log.debug("Matched item name #{p[:name]} for url #{url}")
              item_name = p[:name]
              item_id = p[:id]
              break
            end
          end
          return [item_id, item_name]
        end

        def test_auth()
          unless @auth_success.nil?
            return @auth_success
          end

          response = raw_get(@endpoint + "rest/auth/1/session")
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

