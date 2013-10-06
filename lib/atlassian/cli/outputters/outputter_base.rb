module Atlassian
  module Cli
    module Outputters

      # keep track of all known outputters
      OUTPUTTER_TYPE_MAP = {}

      # NOTE: you should call this in all outputters
      def self.register_outputter(s, type, priority = 1000)
        if OUTPUTTER_TYPE_MAP[type].nil?
          OUTPUTTER_TYPE_MAP[type] = []
        end
        OUTPUTTER_TYPE_MAP[type] << [priority, s.to_s]
      end

      def self.get_outputters(type = nil)
        if type.nil?
          return OUTPUTTER_TYPE_MAP
        end
        return OUTPUTTER_TYPE_MAP[type]
      end

      def self.get_default_outputter(type)
        lowest_so_far = nil
        lowest_so_far_name = nil
        get_outputters(type).each do |op|
          if lowest_so_far.nil? || (lowest_so_far < op[0])
            lowest_so_far = op[0]
            lowest_so_far_name = op[1]
          end
        end
        return lowest_so_far_name
      end

      class OutputterBase

        attr_accessor :display_columns
        attr_accessor :hide_columns

        # called to print the entire object
        def print_object(hash)
          raise "You must extend OutputterBase and implement print_object(hash)"
          # prints the object, respecting @hide_columns and @display_columns
          # if @display_columns is nil, display all
          # if @hide_columns is not empty, reject any keys in it.
        end

        # called to format the data in a single field
        def format_field(hash, key)
          raise "You must extend OutputterBase and implement print_field(hash, key)"
          # return <string to print>
        end

        def initialize(options = {})
          self.hide_columns = options[:hide_columns] || {}
          self.display_columns = options[:display_columns] || nil
        end

        def filter_fields(fields)
          filtered_fields = []
          fields.each do |f|
            if self.display_columns.nil?
              # display all but rejects
              if self.hide_columns[f].nil?
                filtered_fields.push(f)
              end
            else
              # only display te contents of @display_columns
              if self.display_columns[f]
                if !self.hide_columns[f]
                  filtered_fields.push(f)
                end
              end
            end
          end
          return filtered_fields
        end
      end
    end
  end
end
