require 'time'

require 'atlassian/exceptions'

module Atlassian
  module Hashifiers

    class WikiContent
      # this class turns a json object returned by the rest service into a flat hash of wiki content values
      attr_accessor :client

      # mapping to find each column in the structure returned from the rest API
      WIKI_COLUMN_MAP = {
        :body => Proc.new {|s,wiki| wiki[:body][:value] },
        :creator => Proc.new {|s,wiki| wiki[:creator] },
        :lastModifier => Proc.new {|s,wiki| wiki[:lastModifier] },
        :id => Proc.new {|s,wiki| issue[:id] },
        :type => Proc.new {|s,wiki| issue[:type] },
        :parentId => Proc.new {|s,wiki| issue[:parentId] },
        :created => Proc.new {|s,wiki| wiki[:createdDate][:date] },
        :updated => Proc.new {|s,wiki| wiki[:lastModifiedDate][:date] },

        :default => Proc.new {|s,wiki,colname| wiki[colname] || nil },
        :type => Proc.new {|s,issue,colname| issue[:fields].andand[:issuetype].andand[:name] },
        :comments => Proc.new {|s,issue| s.include_comments ? s.client.get_comments_for_issue(issue).andand[:comments].collect {|x| { :displayName => x[:author][:displayName], :name => x[:author][:name], :body => x[:body], :created => x[:created] } } : nil },
      }

      def initialize(options = {})
        @client = options[:client]
        @include_comments = options[:include_comments]
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
          issue_hash[col] = ISSUE_COLUMN_MAP[col].call(self,rest_issue)
        end
        return issue_hash
      end
    end
  end
end



