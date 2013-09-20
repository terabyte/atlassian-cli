require 'time'

require 'atlassian/exceptions'

module Atlassian
  module Hashifiers

    # this class turns a json object returned by the rest service into a flat hash of column-to-value mappings

    class JiraIssue
      # mapping to find each column in the structure returned from the rest API
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
        :resolution => Proc.new {|issue| issue[:fields].andand[:resolution].andand[:name] || "<none>" },
        :fixversions => Proc.new {|issue| issue[:fields].andand[:fixVersions].andand.collect {|x| x[:name] } },
        :affectsversions => Proc.new {|issue| issue[:fields].andand[:versions].andand.collect {|x| x[:name] } },
        :components => Proc.new {|issue| issue[:fields].andand[:components].andand.collect {|x| x[:name] } },
        :default => Proc.new {|issue,colname| issue[:fields].andand[colname] || nil },
        :comments => Proc.new {|issue| issue[:fields].andand[:comments].andand.collect {|x| { :displayName => x[:author][:displayName], :name => x[:author][:name], :body => x[:body] } } },
      }

      # indicates the weight of each column for sorting.  I made these values up.
      # smaller number -> appears earlier
      # TODO: belongs in view layer.
      COLUMN_SORTING_MAP = {
        :id              => 10100,
        :key             => 11000,

        :priority        => 20100,
        :status          => 20200,
        :resolution      => 20300,

        :reporter        => 21100,
        :assignee        => 21200,

        :created         => 22000,
        :updated         => 22100,

        :components      => 25100,
        :fixversions     => 25200,
        :affectsversions => 25300,

        :summary         => 30000,
        :description     => 30100,

        :url             => 80100,
      }

      # TODO: belongs elsewhere
      COLUMN_FORMATTING_MAP = {
        :id => Proc.new {|f,str| str.to_s.green },
        :key => Proc.new {|f,str| str.to_s.green },
        :name => Proc.new {|f,str| str.to_s.greenish },
        :reporter => Proc.new {|f,str| str.to_s.greenish },
        :assignee => Proc.new {|f,str| str.to_s.greenish },
        :displayName => Proc.new {|f,str| str.to_s.yellowish },
        :default => Proc.new {|f,str| str.to_s },
        :priority => Proc.new {|f,str| str.to_s.red },
        :status => Proc.new {|f,str| str.to_s.red },
        :summary => Proc.new {|f,str| f.whitespace_fixup(str.to_s) },
        :description => Proc.new {|f,str| f.whitespace_fixup(str.to_s) },
        :body => Proc.new {|f,str| f.whitespace_fixup(str.to_s) },
        :created => Proc.new {|f, str| Time.parse(str).localtime.strftime("%c").white },
        :updated => Proc.new {|f, str| Time.parse(str).localtime.strftime("%c").white },
        :fixversions => Proc.new {|f,arr| (arr.nil? || arr.empty?) ? '' : ("'" + arr.join("', '") + "'").cyan },
        :affectsversions => Proc.new {|f,arr| (arr.nil? || arr.empty?) ? '' : ("'" + arr.join("', '") + "'").cyan },
        :components => Proc.new {|f,arr| (arr.nil? || arr.empty?) ? '' : ("'" + arr.join("', '") + "'").yellowish },
        :resolution => Proc.new {|f,str| str.to_s.red },
      }

      # TODO: belongs elsewhere
      attr_accessor :color

      def initialize(options = {})
        # TODO: belongs elsewhere
        @color = options[:color]
      end

      # TODO: belongs elsewhere
      def get_column(col, issue)
        if ISSUE_COLUMN_MAP[col]
          ISSUE_COLUMN_MAP[col].call(issue)
        else
          ISSUE_COLUMN_MAP[:default].call(issue, col)
        end
      end

      # sorts columns by the weight
      # TODO: belongs elsewhere
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

      def get_hash(rest_issue)
        issue_hash = {}
        ISSUE_COLUMN_MAP.keys.sort.each do |col|
          issue_hash[col] = ISSUE_COLUMN_MAP[col].call(rest_issue)
        end
        return issue_hash
      end

      # TODO: belongs elsewhere
      def format_text_by_column(col, data)
        if COLUMN_FORMATTING_MAP[col]
          COLUMN_FORMATTING_MAP[col].call(self, data)
        else
          COLUMN_FORMATTING_MAP[:default].call(self, data)
        end
      end

      # '\r" ends up embedded in places due to windows copy/paste and messes up everything.
      # TODO: belongs elsewhere
      def whitespace_fixup(text)
        text.andand.gsub(/\r/, "")
      end

    end
  end
end



