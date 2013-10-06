require 'json'

require 'atlassian/cli/outputters/outputter_base'

module Atlassian
  module Cli
    module Outputters
      module Json
        class JiraIssueList < Atlassian::Cli::Outputters::OutputterBase

          Atlassian::Cli::Outputters.register_outputter(self, :jira_issue_list, 100)

          def initialize(options = {})
            super(options)
          end

          # called to print the entire object
          # in this case, hash is actually an array of objects
          def print_object(issues)
            # TODO: use filter_fields?
            return issues.to_json
          end
        end # class JiraIssueList
      end
    end
  end
end
