require 'highline'
require 'terminal-table'

require 'atlassian/formatters/jira_issue'


module Atlassian
  module Cli
    module Outputters
      class JiraIssue

        DEFAULT_COLUMNS = %w{ key status reporter assignee summary }.collect {|x| x.to_sym}

        attr_accessor :display_columns
        attr_accessor :formatter

        def initialize(options = {})
          @display_columns = DEFAULT_COLUMNS

          if options[:color].nil?
            options[:color] = true
          end
          @formatter = Atlassian::Formatters::JiraIssue.new(:color => options[:color])
        end

        def display_issue_table(issue, comments = [])
          issue_map = @formatter.get_issue_map(issue)
          table = Terminal::Table.new do |t|
            width, height = HighLine::SystemExtensions.terminal_size
            # XXX TODO: bug in the gem prevents this currently
            #t.style = {:width => width}

            @formatter.sort_cols(issue_map.keys).each do |col|
              t << [{:value => header(col), :alignment => :right}, @formatter.format_text_by_column(col, issue_map[col])]
            end
            comments.each do |c|
              name = @formatter.format_text_by_column(:displayName, c[:author][:displayName]) + " (" + @formatter.format_text_by_column(:name, c[:author][:name]) + ")\n" + @formatter.format_text_by_column(:created, c[:created])
              body = @formatter.format_text_by_column(:body, c[:body])

              t << :separator
              t << [{:value => name, :alignment => :center}, body]
            end
          end
        end

        def display_issues_table(issues)

          table = Terminal::Table.new do |t|
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

        def header(str)
          str.to_s.capitalize.blue
        end
      end # class JiraIssue
    end
  end
end

