require 'time'

module Atlassian
  module Hashifiers

    class JiraComponent
      # this class turns a json object returned by the rest service into a flat hash of column-to-value mappings
      attr_accessor :client

      # mapping to find each column in the structure returned from the rest API
      COMPONENT_COLUMN_MAP = {
        :id => Proc.new {|s,comp| comp[:id] },
        :name => Proc.new {|s,comp| comp[:name] },
        :description => Proc.new {|s,comp| comp[:description] },
        :lead => Proc.new {|s,comp| comp[:lead].andand[:name] },
      }

      def initialize(options = {})
        @client = options[:client]
      end

      def get_hash(rest_component)
        component_hash = {}
        COMPONENT_COLUMN_MAP.keys.sort.each do |col|
          component_hash[col] = COMPONENT_COLUMN_MAP[col].call(self,rest_component)
        end
        return component_hash
      end
    end
  end
end



