module Atlassian
  module Cli
    module Outputters
      module Table

        # shared definitions for jira issues (sorting, formatting, etc)
        module JiraIssueBase

          # indicates the weight of each column for sorting.  I made these values up.
          # smaller number -> appears earlier
          # TODO: belongs in view layer.
          COLUMN_SORTING_MAP = {
            :id              => 10100,
            :key             => 11000,

            :priority        => 20100,
            :status          => 20200,
            :resolution      => 20300,
            :type            => 20400,

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

          COLUMN_FORMATTING_MAP = {
            :id => Proc.new {|f,hash,key| f.color ? hash[key].to_s.green : hash[key].to_s },
            :key => Proc.new {|f,hash,key| f.color ? hash[key].to_s.green : hash[key].to_s },
            :name => Proc.new {|f,hash,key| f.color ? hash[key].to_s.greenish : hash[key].to_s },
            :reporter => Proc.new {|f,hash,key| f.color ? hash[key].to_s.greenish : hash[key].to_s },
            :assignee => Proc.new {|f,hash,key| f.color ? hash[key].to_s.greenish : hash[key].to_s },
            :displayName => Proc.new {|f,hash,key| f.color ? hash[key].to_s.yellowish : hash[key].to_s },
            :default => Proc.new {|f,hash,key| hash[key].to_s },
            :priority => Proc.new {|f,hash,key| f.color ? hash[key].to_s.red : hash[key].to_s },
            :type => Proc.new {|f,hash,key| f.color ? hash[key].to_s.red : hash[key].to_s },
            :status => Proc.new {|f,hash,key| status = (hash[:resolution].nil? ? hash[:status] : hash[:status] + " (#{hash[:resolution]})"); f.color ? status.to_s.red : status.to_s },
            :summary => Proc.new {|f,hash,key| f.whitespace_fixup(hash[key].to_s) },
            :description => Proc.new {|f,hash,key| f.whitespace_fixup(hash[key].to_s) },
            :body => Proc.new {|f,hash,key| f.whitespace_fixup(hash[key].to_s) },
            :created => Proc.new {|f,hash,key| s = hash[key].nil? ? "nil" : Time.parse(hash[key]).localtime.strftime("%c"); f.color ? s.white : s },
            :updated => Proc.new {|f,hash,key| s = hash[key].nil? ? "nil" : Time.parse(hash[key]).localtime.strftime("%c"); f.color ? s.white : s },
            :fixversions => Proc.new {|f,hash,key| s = (hash[key].nil? || hash[key].empty?) ? '' : ("'" + hash[key].join("', '") + "'"); f.color ? s.cyan : s },
            :affectsversions => Proc.new {|f,hash,key| s = (hash[key].nil? || hash[key].empty?) ? '' : ("'" + hash[key].join("', '") + "'"); f.color ? s.cyan : s },
            :components => Proc.new {|f,hash,key| s = (hash[key].nil? || hash[key].empty?) ? '' : ("'" + hash[key].join("', '") + "'"); f.color ? s.yellowish : s },
            :resolution => Proc.new {|f,hash,key| f.color ? hash[key].to_s.red : hash[key].to_s },
            # yeah, this one is crazy because it formats the non-flat comment structure
            :commentAuthor => Proc.new {|f,hash,key| n = hash[:displayName].to_s; un = COLUMN_FORMATTING_MAP[:name].call(f,hash,:name); d = COLUMN_FORMATTING_MAP[:created].call(f,hash,:created); if f.color then n = n.yellowish; end; n + " (" + un + ")\n" + d },
            #:commentAuthor => Proc.new {|f,hash,key| n = hash[:displayName].to_s.yellowish + " (" + COLUMN_FORMATTING_MAP[:name].call(f,hash,:name) + ")\n" + COLUMN_FORMATTING_MAP[:created].call(f,hash,:created) },
          }

          # TODO: is this a special case?
          DEFAULT_COLUMN_MAP = {
            :key => true,
            :reporter => true,
            :assignee => true,
            :status => true,
            :priority => true,
            :summary => true,
            :description => true,
            :created => true,
            :updated => true,
            :fixversions => true,
            :affectsversions => true,
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
