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
            # prints the object, respecting @hide_columns and @display_columns (by using filter_fields())
            if hash.is_a? Array
              # support printing multiple issues too...
              output = ""
              hash.each do |item|
                output = output + print_object(item).to_s
              end
              return output
            end

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
              # list links next
              if !hash[:links].andand.empty?
                t << :separator
                # TODO: figure out how to make this span two columns?
                t << [{:value => "Issue Links".blue, :alignment => :center}, ""]
              end
              hash[:links].andand.each do |link|
                # determine if incoming or outgoing
                typename = link[:type][:name]
                leftkey = nil
                rightkey = nil
                linktext = nil
                otherkey = nil
                othersummary = nil
                otherstatus = nil
                if link[:inwardIssue]
                  rightkey = format_field(link[:inwardIssue], :key)
                  # strip out parent so we don't get "TEST-1 (sub-task of TEST-2) here - it is already displayed elsewhere
                  leftkey = format_field(hash.reject {|k,v| k == :parent }, :key)
                  otherkey = rightkey
                  linktext = link[:type][:inwardtext]

                  othersumamry = link[:inwardIssue][:summary] # TODO: maybe format_field(link[:outwardIssue], :sumamry)
                  otherstatus = format_field(link[:inwardIssue], :status)
                elsif link[:outwardIssue]
                  # strip out parent so we don't get "TEST-1 (sub-task of TEST-2) here - it is already displayed elsewhere
                  leftkey = format_field(hash.reject {|k,v| k == :parent }, :key)
                  rightkey = format_field(link[:outwardIssue], :key)
                  otherkey = rightkey
                  linktext = link[:type][:outwardtext]

                  othersumamry = link[:outwardIssue][:summary] # TODO: maybe format_field(link[:outwardIssue], :sumamry)
                  otherstatus = format_field(link[:outwardIssue], :status)
                end
                t << [{:value => "#{leftkey} #{linktext} #{rightkey}", :alignment => :right}, "#{otherkey} (#{otherstatus}): #{othersumamry}"]
              end

              # list attachments if not empty
              if !hash[:attachments].andand.empty?
                t << :separator
                # TODO: figure out how to make this span two columns?
                t << [{:value => "Attachments".blue, :alignment => :center}, ""]
                hash[:attachments].andand.each do |at|
                  name = format_field(at, :commentAuthor)
                  url = format_field(at, :attachmentUrl)
                  t << [{:value => name, :alignment => :right}, url]
                end
              end

              # list subtasks if not empty
              if !hash[:subtasks].andand.empty?
                t << :separator
                # TODO: figure out how to make this span two columns?
                t << [{:value => "Sub-Tasks".blue, :alignment => :center}, ""]
              end
              hash[:subtasks].andand.each do |st|
                key = format_field(st, :key)
                status = format_field(st, :status)
                summary = format_field(st, :summary)
                t << [{:value => "(#{status}) #{key}", :alignment => :right}, summary]
              end

              # list comments last
              if !hash[:comments].andand.empty?
                t << :separator
                # TODO: figure out how to make this span two columns?
                t << [{:value => "Comments".blue, :alignment => :center}, ""]
              end
              hash[:comments].andand.each do |c|

                name = format_field(c, :commentAuthor)
                body = format_field(c, :body)
                t << :separator
                t << [{:value => name, :alignment => :right}, body]
              end

            end
          end
        end # class JiraIssue
      end
    end
  end
end
