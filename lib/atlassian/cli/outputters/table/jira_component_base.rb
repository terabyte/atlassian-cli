require 'highline'
require 'terminal-table'

module Atlassian
  module Cli
    module Outputters
      module Table

        # shared definitions for jira modules (sorting, formatting, etc)
        module JiraComponentBase

          # indicates the weight of each column for sorting.  I made these values up.
          # smaller number -> appears earlier
          # TODO: belongs in view layer.
          COLUMN_SORTING_MAP = {
            :id              => 10100,
            :lead            => 10500,
            :name            => 11000,
            :description     => 30100,
          }

          COLUMN_FORMATTING_MAP = {
            :id => Proc.new {|f,hash,key| f.color ? hash[key].to_s.green : hash[key].to_s },
            :name => Proc.new {|f,hash,key| f.color ? hash[key].to_s.greenish : hash[key].to_s },
            :lead => Proc.new {|f,hash,key| f.color ? hash[key].to_s.greenish : hash[key].to_s },
            :default => Proc.new {|f,hash,key| hash[key].to_s },
            :description => Proc.new {|f,hash,key| f.whitespace_fixup(hash[key].to_s) },
          }

          # TODO: is this a special case?
          DEFAULT_COLUMN_MAP = {
            :id => true,
            :lead => true,
            :name => true,
            :description => true,
          };


          def format_field(hash, key)
            if COLUMN_FORMATTING_MAP[key]
              COLUMN_FORMATTING_MAP[key].call(self, hash, key)
            else
              COLUMN_FORMATTING_MAP[:default].call(self, hash, key)
            end
          end

          # sorts columns by the weight, placing any not in the map at the end alphabetically
          def sort_fields(fields)
            fields.sort {|a,b| (COLUMN_SORTING_MAP[a] || a).to_s <=> (COLUMN_SORTING_MAP[b] || b).to_s }
          end

          # '\r" ends up embedded in places due to windows copy/paste and messes up everything.
          def whitespace_fixup(text)
            text.andand.gsub(/\r/, "")
          end

          def parse_column_options(options)
            display_columns = options[:display_columns]
            if display_columns.nil?
              display_columns = DEFAULT_COLUMN_MAP
            end
            hide_columns = options[:hide_columns]
          end
        end
      end
    end
  end
end
