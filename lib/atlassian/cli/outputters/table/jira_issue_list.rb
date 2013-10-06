require 'highline'
require 'terminal-table'

module Atlassian
  module Cli
    module Outputters
      module Table
        class JiraIssueList < Atlassian::Cli::Outputters::OutputterBase

          attr_accessor :color
          attr_accessor :set_width

          # shared functionality like colors, etc
          # Specifically, defines: format_field(hash, key) and sort_fields(fields)
          include Atlassian::Cli::Outputters::Table::JiraIssueBase

          Atlassian::Cli::Outputters.register_outputter(self, :jira_issue_list, 1000)

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
          # in this case, hash is actually an array of objects
          def print_object(issues)
            if issues.nil?
              raise "nil issue"
            end
            if !issues.is_a? Array
              issues = [issues]
            end

            if issues.empty?
              # XXX TODO: better messaging?
              return
            end

            table = Terminal::Table.new do |t|
              if @set_width
                width, height = HighLine::SystemExtensions.terminal_size
                t.style = {:width => width}
              end
              header = []
              sorted_fields = sort_fields(filter_fields(issues.first.keys))
              sorted_fields.each do |key|
                h = key.to_s.capitalize
                h = h.blue if @color
                header << h
              end

              t << header
              t << :separator

                issues.each do |hash|
                  row = []
                  sorted_fields.each do |key|
                    row << format_field(hash, key)
                  end
                  t << row
                end
            end
          end
        end # class JiraIssueList
      end
    end
  end
end
