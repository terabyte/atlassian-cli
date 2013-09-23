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

          # TODO: check f.color ?
          COLUMN_FORMATTING_MAP = {
            :id => Proc.new {|f,hash,key| hash[key].to_s.green },
            :key => Proc.new {|f,hash,key| hash[key].to_s.green },
            :name => Proc.new {|f,hash,key| hash[key].to_s.greenish },
            :reporter => Proc.new {|f,hash,key| hash[key].to_s.greenish },
            :assignee => Proc.new {|f,hash,key| hash[key].to_s.greenish },
            :displayName => Proc.new {|f,hash,key| hash[key].to_s.yellowish },
            :default => Proc.new {|f,hash,key| hash[key].to_s },
            :priority => Proc.new {|f,hash,key| hash[key].to_s.red },
            :status => Proc.new {|f,hash,key| hash[key].to_s.red },
            :summary => Proc.new {|f,hash,key| f.whitespace_fixup(hash[key].to_s) },
            :description => Proc.new {|f,hash,key| f.whitespace_fixup(hash[key].to_s) },
            :body => Proc.new {|f,hash,key| f.whitespace_fixup(hash[key].to_s) },
            :created => Proc.new {|f,hash,key| hash[key].nil? ? "nil" : Time.parse(hash[key]).localtime.strftime("%c").white },
            :updated => Proc.new {|f,hash,key| hash[key].nil? ? "nil" : Time.parse(hash[key]).localtime.strftime("%c").white },
            :fixversions => Proc.new {|f,hash,key| (hash[key].nil? || hash[key].empty?) ? '' : ("'" + hash[key].join("', '") + "'").cyan },
            :affectsversions => Proc.new {|f,hash,key| (hash[key].nil? || hash[key].empty?) ? '' : ("'" + hash[key].join("', '") + "'").cyan },
            :components => Proc.new {|f,hash,key| (hash[key].nil? || hash[key].empty?) ? '' : ("'" + hash[key].join("', '") + "'").yellowish },
            :resolution => Proc.new {|f,hash,key| hash[key].to_s.red },
            # yeah, this one is crazy
            :commentAuthor => Proc.new {|f,hash,key| puts "QQQ: #{hash.inspect}\n\n"; hash[:displayName].to_s.yellowish + " (" + COLUMN_FORMATTING_MAP[:name].call(f,hash,:name) + ")\n" + COLUMN_FORMATTING_MAP[:created].call(f,hash,:created) },
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
        end
      end
    end
  end
end
