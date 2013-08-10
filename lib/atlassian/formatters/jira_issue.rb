require 'time'

require 'atlassian/exceptions'

module Atlassian
  module Formatters

    # indicates how to find a column in the nested structure of an issue
    ISSUE_COLUMN_MAP = {
      :id => Proc.new {|issue| issue[:id] },
      :key => Proc.new {|issue| issue[:key] },
      :url => Proc.new {|issue| issue[:self] },
      :description => Proc.new {|issue| issue[:fields].andand[:description] },
      :created => Proc.new {|issue| issue[:fields].andand[:created] },
      :updated => Proc.new {|issue| issue[:fields].andand[:updated] },
      :priority => Proc.new {|issue| issue[:fields].andand[:priority].andand[:name] },
      :status => Proc.new {|issue| issue[:fields].andand[:status].andand[:name] },
      :summary => Proc.new {|issue| issue[:fields].andand[:summary] },
      :assignee => Proc.new {|issue| issue[:fields].andand[:assignee].andand[:name] },
      :reporter => Proc.new {|issue| issue[:fields].andand[:reporter].andand[:name] },
      :fixversions => Proc.new {|issue| issue[:fields].andand[:fixVersions].andand.collect {|x| x[:name] } },
      :components => Proc.new {|issue| issue[:fields].andand[:components].andand.collect {|x| x[:name] } },
      :default => Proc.new {|issue,colname| issue[:fields].andand[colname] || nil },
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
      :id => Proc.new {|f,str| str.to_s.green },
      :key => Proc.new {|f,str| str.to_s.green },
      :name => Proc.new {|f,str| str.to_s.green },
      :displayName => Proc.new {|f,str| str.to_s.yellow },
      :default => Proc.new {|f,str| str.to_s },
      :priority => Proc.new {|f,str| str.to_s.red },
      :status => Proc.new {|f,str| str.to_s.red },
      :summary => Proc.new {|f,str| f.shorten(str.to_s) },
      :description => Proc.new {|f,str| f.shorten(str.to_s) },
      :body => Proc.new {|f,str| f.shorten(str.to_s) },
      :created => Proc.new {|f, str| Time.parse(str).localtime.strftime("%c") },
      :updated => Proc.new {|f, str| Time.parse(str).localtime.strftime("%c") },
    }

    # this class turns a json object returned by the rest service into a flat hash of column-to-value mappings
    class JiraIssue
      attr_accessor :color

      def initialize(options = {})
        @color = options[:color]
      end

      def get_column(col, issue)
        if ISSUE_COLUMN_MAP[col]
          ISSUE_COLUMN_MAP[col].call(issue)
        else
          ISSUE_COLUMN_MAP[:default].call(issue, col)
        end
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
        sort_cols(ISSUE_COLUMN_MAP.keys).reject {|x| x == :default}.each do |col|
          issue_map[col] = ISSUE_COLUMN_MAP[col].call(issue)
        end
        return issue_map
      end

      def format_text_by_column(col, data)
        if COLUMN_FORMATTING_MAP[col]
          COLUMN_FORMATTING_MAP[col].call(self, data)
        else
          COLUMN_FORMATTING_MAP[:default].call(self, data)
        end
      end

      # try to cut out crazy whitespace / or other weird characters in
      # free-form text input fields where people often paste-spew
      def shorten(text)
        text.andand.gsub(/\s{3,}/, " ").andand.gsub(/\r/, "")
      end

    end
  end
end



