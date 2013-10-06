require 'json'

require 'atlassian/cli/outputters/outputter_base'

module Atlassian
  module Cli
    module Outputters
      module Json
        class JiraIssue < Atlassian::Cli::Outputters::OutputterBase

          Atlassian::Cli::Outputters.register_outputter(self, :jira_issue, 100)

          def initialize(options = {})
            super(options)
          end

          # called to print the entire object
          def print_object(hash)
            # TODO: use filter_fields?
            return hash.to_json
          end
        end # class JiraIssue
      end
    end
  end
end
