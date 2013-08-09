
module Atlassian
  module Cli
    class Credentials

      attr_accessor :credential_getters

      def initialize
        @credential_getters = []
        @credential_getters << NetRc.new()
        @credential_getters << Prompt.new()
      end

      # main credential retreiving entrypoint
      def get_credentials
        @credential_getters.each do |c|
          begin
            user, pw = c.get_credentials
            if user && pw
              return [user, pw]
            end
          rescue Exception => e
            # ignore errors, try our best to get creds.  maybe highline missing?
          end
        end
        # no credentials found, try anonymous
        return ["", ""]
      end


      # implementations

      class NetRc

        NETRC_PATH = '.netrc'
        NETRC_HOST = 'atlassian-cli.example.com'

        def get_credentials
          File.open(File.join("#{Dir.home}", NETRC_PATH)) do |f|
            found_start = false
            username = nil
            password = nil
            f.each_line do |l|
              break if found_start && username && password

              if l.match("^machine #{NETRC_HOST}$")
                found_start = true
                next
              end

              next unless found_start

              if l.match("^login (.*)$")
                username = $1
                next
              end

              if l.match("^password (.*)$")
                password = $1
                next
              end
            end

            if found_start && username && password
              return [username, password]
            end
            return [nil, nil]
          end
        end

      end # end class NetRc

      class Prompt

        def get_credentials

          # needed to prompt for pw
          require 'highline/import'

          return [get_user, get_password]
        end

        def get_text(prompt, echo = true)
          ask(prompt) do |q|
            q.echo = echo
          end
        end

        def get_user
          get_text("Username: ", true)
        end

        def get_password
          get_text("Password: ", false)
        end
      end


    end
  end
end



