module Atlassian
  module Cli
    module Outputters
      class OutputterBase

        # called to print the entire object
        def print_object(hash)
          raise "You must extend OutputterBase and implement print_object(hash)"
          # prints the object, respecting @reject_columns and @display_columns
          # if @display_columns is nil, display all
          # if @reject_columns is not empty, reject any keys in it.
        end

        # called to format the data in a single field
        def format_field(hash, key)
          raise "You must extend OutputterBase and implement print_field(hash, key)"
          # return <string to print>
        end

        def initialize(options = {})
          @reject_columns = options[:reject_columns] || {}
          @display_columns = options[:reject_columns] || nil
        end

        def filter_fields(fields)
          filtered_fields = []
          fields.each do |f|
            if @display_columns.nil?
              # display all but rejects
              if @reject_columns[f].nil?
                filtered_fields.push(f)
              end
            else
              # only display te contents of @display_columns
              if @display_columns[f]
                if !@reject_columns[f]
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
