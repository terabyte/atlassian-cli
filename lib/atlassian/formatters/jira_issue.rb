require 'atlassian/exceptions'

module Atlassian
  module Formatters

    # indicates how to find a column in the nested structure of an issue
    ISSUE_COLUMN_MAP = {
      :id => Proc.new {|issue| issue[:id] },
      :key => Proc.new {|issue| issue[:key] },
      :url => Proc.new {|issue| issue[:self] },
      :description => Proc.new {|issue| issue[:fields][:description] },
      :created => Proc.new {|issue| issue[:fields][:created] },
      :updated => Proc.new {|issue| issue[:fields][:updated] },
      :priority => Proc.new {|issue| issue[:fields][:priority][:name] },
      :status => Proc.new {|issue| issue[:fields][:status][:name] },
      :summary => Proc.new {|issue| issue[:fields][:summary] },
      :assignee => Proc.new {|issue| issue[:fields][:assignee][:name] },
      :reporter => Proc.new {|issue| issue[:fields][:reporter][:name] },
      :fixversions => Proc.new {|issue| issue[:fields][:fixversions].andand.collect {|x| x[:name] } }, # TODO: is this right?
      :components => Proc.new {|issue| issue[:fields][:components].andand.collect {|x| x[:name] } },
    }

    # indicates the weight of each column for sorting.  I made these values up.
    # smaller number -> appears earlier
    COLUMN_SORTING_MAP = {
      :id          => 10100,
      :key         => 11000,

      :priority    => 20100,
      :status      => 20200,
      :resolution  => 20300,

      :reporter    => 21100,
      :assignee    => 21200,

      :created     => 22000,
      :updated     => 22100,

      :components  => 25100,
      :fixversions => 25200,

      :summary     => 30000,
      :description => 30100,

      :url         => 80100,
    }

    COLUMN_FORMATTING_MAP = {
      :id => Proc.new {|str| str.to_s.green },
      :key => Proc.new {|str| str.to_s.green },
      :default => Proc.new {|str| str.to_s },
      :priority => Proc.new {|str| str.to_s.red },
      :status => Proc.new {|str| str.to_s.red },
    }

    # this class turns a json object returned by the rest service into a flat hash of column-to-value mappings
    class JiraIssue
      attr_accessor :color

      def initialize(options = {})
        @color = options[:color]
      end

      def get_column(col, issue)
        ISSUE_COLUMN_MAP.values_at(col).andand.first.andand.call(issue)
      end

      # sorts columns by the weight
      def sort_cols(cols)
        cols.sort {|a,b| COLUMN_SORTING_MAP[a].to_s <=> COLUMN_SORTING_MAP[b].to_s }
      end

      def get_row(cols, issue)
        row = []
        cols.each do |col|
          data = get_column(col, issue)
          data = format_text_by_column(col, data)
          row << data
        end
        row
      end

      def get_issue_map(issue)
        issue_map = {}
        sort_cols(ISSUE_COLUMN_MAP.keys).each do |col|
          issue_map[col] = ISSUE_COLUMN_MAP[col].call(issue)
        end
        return issue_map
      end

      def format_text_by_column(col, data)
        if COLUMN_FORMATTING_MAP[col]
          COLUMN_FORMATTING_MAP[col].call(data)
        else
          COLUMN_FORMATTING_MAP[:default].call(data)
        end
      end
    end
  end
end



