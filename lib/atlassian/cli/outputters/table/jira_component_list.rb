require 'highline'
require 'terminal-table'
require 'atlassian/cli/outputters/table/jira_component_base'

module Atlassian
  module Cli
    module Outputters
      module Table
        class JiraComponentList < Atlassian::Cli::Outputters::OutputterBase

          attr_accessor :color
          attr_accessor :set_width

          # shared functionality like colors, etc
          # Specifically, defines: format_field(hash, key) and sort_fields(fields)
          include Atlassian::Cli::Outputters::Table::JiraComponentBase

          Atlassian::Cli::Outputters.register_outputter(self, :jira_component_list, 1000)

          def initialize(options = {})

            super(options)

            # from JiraComponentBase
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
          def print_object(components)
            if components.nil?
              raise "nil component"
            end
            if !components.is_a? Array
              components = [components]
            end

            count = components.length
            if components.empty?
              return "0 rows returned"
            end

            table = Terminal::Table.new do |t|
              if @set_width
                width, height = HighLine::SystemExtensions.terminal_size
                t.style = {:width => width}
              end
              header = []
              sorted_fields = sort_fields(filter_fields(components.first.keys))
              sorted_fields.each do |key|
                h = key.to_s.capitalize
                h = h.blue if @color
                header << h
              end

              t << header
              t << :separator

                components.each do |hash|
                  row = []
                  sorted_fields.each do |key|
                    row << format_field(hash, key)
                  end
                  t << row
                end
            end.to_s + "#{count} rows returned"
          end
        end # class JiraComponentList
      end
    end
  end
end
