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

          def initialize(options = {})

            super(options)

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
                t << [{:value => key.to_s.capitalize.blue, :alignment => :right}, format_field(hash, key)]
              end
              # list comments at the end
              comments.each do |c|

                name = format_field(c, :commentAuthor)
                body = format_field(c, :body)
                t << :separator
                  t << [{:value => name, :alignment => :center}, body]
              end
            end
          end

          # TODO: delete
          def display_issues_table(issues)

            table = Terminal::Table.new do |t|
              if @set_width
                width, height = HighLine::SystemExtensions.terminal_size
                t.style = {:width => width}
              end
              sorted_cols = @formatter.sort_cols(@display_columns)
              header = []
              sorted_cols.each do |col|
                header << header(col)
              end

              t << header
              t << :separator

                issues.each do |issue|
                t << @formatter.get_row(sorted_cols, issue).each
                end
            end
          end

          # TODO: delete
          def display_issue_field(issue, field)
            issue_map = @formatter.get_issue_map(issue)
            puts issue_map[field]
          end

          # TODO: delete
          def header(str)
            str.to_s.capitalize.blue
          end
        end # class JiraIssue
      end
    end
  end
end
