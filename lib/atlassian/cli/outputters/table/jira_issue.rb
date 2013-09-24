require 'highline'
require 'terminal-table'

require 'atlassian/cli/outputters/outputter_base'
require 'atlassian/cli/outputters/table/jira_issue_base'

module Atlassian
  module Cli
    module Outputters
      module Table
        class JiraIssue < Atlassian::Cli::Outputters::OutputterBase

          attr_accessor :color
          attr_accessor :set_width

          # shared functionality like colors, etc
          # Specifically, defines: format_field(hash, key) and sort_fields(fields)
          include Atlassian::Cli::Outputters::Table::JiraIssueBase

          Atlassian::Cli::Outputters.register_outputter(self, :jira_issue, 1000)

          def initialize(options = {})

            super(options)

            # from JiraIssueBase
            parse_column_options(options)

            @set_width = options[:set_width]
            if @set_width.nil?
              @set_width = true
            end

            @color = options[:color]
            if @color.nil?
              @color = true
            end
          end

          # called to print the entire object
          def print_object(hash)
            # prints the object, respecting @reject_columns and @display_columns (by using filter_fields())
            table = Terminal::Table.new do |t|
              if @set_width
                width, height = HighLine::SystemExtensions.terminal_size
                t.style = {:width => width}
              end

              sort_fields(filter_fields(hash.keys)).each do |key|
                next if key == :comments
                header = key.to_s.capitalize
                header = header.blue if @color
                t << [{:value => header, :alignment => :right}, format_field(hash, key)]
              end
              # list comments at the end
              hash[:comments].andand.each do |c|

                name = format_field(c, :commentAuthor)
                body = format_field(c, :body)
                t << :separator
                  t << [{:value => name, :alignment => :center}, body]
              end
            end
          end
        end # class JiraIssue
      end
    end
  end
end
