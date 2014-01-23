
require 'httpclient'
require 'json'
require 'log4r'

require 'atlassian/rest/exceptions'

module Atlassian
  module Rest

    module HttpStatus
      class HttpBaseStatus < Exception
        attr_accessor :content
        attr_accessor :message
        attr_accessor :status

        def initialize(status)
          initialize(status, nil, nil)
        end

        def initialize(status, content)
          initialize(status, content, nil)
        end

        def initialize(status, content, message)
          @status = status
          @content = content
          @message = message
        end

        def to_s
          self.class.to_s + "(#{@status}): \n\tMessage: '#{@message}'\n\tContent: '#{@content}'"
        end
      end

      # >= 400
      class HttpError < HttpBaseStatus
      end

      # 4XX
      class HttpClientError < HttpError
      end

      # 5XX
      class HttpServerError < HttpError
      end
    end

    # baseclass for all atlassian rest clients
    class Client

      DEFAULT_COOKIE_FILE=File.join(Dir.home, '.atlas-cli-cookie')

      include Log4r
      include HttpStatus

      attr_accessor :endpoint
      attr_accessor :log
      attr_accessor :password
      attr_accessor :raw_http_client
      attr_accessor :timeout
      attr_accessor :username
      attr_accessor :extra_headers
      attr_accessor :cookie_file
      attr_accessor :need_credentials

      def initialize(options)
        @extra_headers = {}
        if options[:logger]
          @log = options[:logger]
        else
          @log = Logger.new self.class.to_s
          @log.outputters = Outputter.stdout
        end

        if options[:endpoint]
          @endpoint = options[:endpoint]
          if !@endpoint.match("/$")
            @endpoint = @endpoint + "/"
          end
        end

        raise ArgumentError.new(":endpoint is required") unless @endpoint

        if options[:username]
          @username = options[:username]
        end

        if options[:password]
          @password = options[:password]
        end

        if options[:timeout]
          @timeout = options[:timeout]
        end

        if options[:httpclient]
          @raw_http_client = options[:httpclient]
        else
          @raw_http_client = HTTPClient.new
        end
        if @timeout
          @raw_http_client.connect_timeout = @timeout
          @raw_http_client.send_timeout = @timeout
          @raw_http_client.receive_timeout = @timeout
        end

        if options[:cacert]
          @log.debug "Adding custom CA certificate #{options[:cacert]}"
          @raw_http_client.ssl_config.add_trust_ca(options[:cacert])
        end

        if options[:cookie_file]
          @cookie_file = options[:cookie_file]
        else
          @cookie_file = DEFAULT_COOKIE_FILE
        end

        unless options[:disable_cookies]
          # if cookies don't exist, ensure we create them safely
          unless File.readable? @cookie_file
            @log.debug "Creating cookie jar for auth"
            # touch the file
            File.open(@cookie_file, 'w').close()
            # set perms
            File.chmod(0600, @cookie_file)
            @raw_http_client.set_cookie_store(@cookie_file)
          else
            @raw_http_client.set_cookie_store(@cookie_file)
            @raw_http_client.cookie_manager.load_cookies()
            @log.debug "Cookie jar exists, trying"
            if test_auth
              @log.debug "Auth success with cookie credentials"
            else
              @log.debug "Auth fails with cookie credentials, username/pw is needed"
              @need_credentials = true
            end
          end
        end
      end

      # Lets us see if we are authorized, and if not, apply a username/password
      # after object construction
      def ensure_logged_in
        if !test_auth && @username
          @log.debug "Using auth credentials username #{@username}"
          @raw_http_client.set_auth(nil, @username, @password)
          # this is fucking insane.  Auth isn't sent unless we send this header
          # and httpclient doesn't include it by default.  I *think* this might
          # be because some APIs don't require auth, so jira doesn't just
          # require auth, so httpclient never tries auth unless you tell it to.
          # W T F.
          @extra_headers["Authorization"] = "Basic"
          unless test_auth 
            raise HttpClientError.new("Unable to authenticate")
          end
          # success, no longer need basic auth
          @extra_headers.delete("Authorization")
        end
        #puts "COOKIES: \n\n\n"
        #ap @raw_http_client.cookie_manager
        #exit 1
        # Cookie is not saved by default, we have to jank ourselves in there and force it
        if @log.level == Log4r::DEBUG
          puts "ALL COOKIES: "
          ap @raw_http_client.cookie_manager.cookies
        end
        @raw_http_client.cookie_manager.cookies.each do |c|
          if c.name == "JSESSIONID"
            c.discard = false
            c.http_only = false
            c.url.path = "/"
          end
        end
        if @log.level == Log4r::DEBUG
          puts "ALL COOKIES AFTER: "
          ap @raw_http_client.cookie_manager.cookies
        end
        @raw_http_client.cookie_manager.save_cookies(true)
      end

      # returns an httpclient response object (HTTP::Message)
      # responds to content, status, reason, and contenttype.
      def raw_get(url, parameters = {}, headers = {})
        @log.debug "Performing GET on url #{url}"
        @log.debug "Parameters: #{parameters.to_s}"
        response = @raw_http_client.get(url, parameters, @extra_headers.merge(headers))
        return response
      end

      # returns an httpclient response object (HTTP::Message)
      # responds to content, status, reason, and contenttype.
      def raw_post(url, data = nil, headers = {})
        @log.debug "Performing POST on url #{url}"
        @log.debug "DATA: #{data}"
        response = @raw_http_client.post(url, data, @extra_headers.merge(headers))
        return response
      end

      def raw_delete(url, data = nil, headers = {})
        @log.debug "Performing DELETE on url #{url}"
        @log.debug "DATA: #{data}"
        response = @raw_http_client.delete(url, data, @extra_headers.merge(headers))
        return response
      end

      def raw_put(url, data = nil, headers = {})
        @log.debug "Performing PUT on url #{url}"
        @log.debug "DATA: #{data}"
        response = @raw_http_client.put(url, data, @extra_headers.merge(headers))
        return response
      end

      def raw_update(url, data = nil, headers = {})
        @log.debug "Performing UPDATE on url #{url}"
        @log.debug "DATA: #{data}"
        response = @raw_http_client.update(url, data, @extra_headers.merge(headers))
        return response
      end

      # uses a GET to send json-based query string, returns content on a
      # success, otherwise raises an exception.
      def json_get(path, parameters = {}, headers = {})
        if !headers['Content-Type']
          headers['Content-Type'] = 'application/json'
        end

        uri = @endpoint + path

        @log.debug "JSON GET: " + parameters.to_s

        response = raw_get(uri, parameters, headers)

        status = response.status.to_i
        if status >= 200 && status < 300
          if response.content.size > 1
            parsed = JSON.parse(response.content).deep_symbolize_keys
          else
            # empty means empty - jira does this =(
            parsed = {}
          end
          return parsed
        end

        # some sort of error may have happened, or it could just be a 404 or something.
        begin
          parsed = JSON.parse(response.content).deep_symbolize_keys
          if status < 500
            raise HttpClientError.new(status, parsed, response.reason)
          else
            raise HttpServerError.new(status, parsed, response.reason)
          end
        rescue Exception => e
          raise e if e.is_a?(HttpBaseStatus)
          raise HttpServerError.new(status, response.content, response.reason)
        end
      end

      def json_post(path, parameters = {}, headers = {})
        if !headers['Content-Type']
          headers['Content-Type'] = 'application/json'
        end

        uri = @endpoint + path

        @log.debug "JSON POST: " + parameters.to_json

        response = raw_post(uri, parameters.to_json, headers)

        status = response.status.to_i
        if status >= 200 && status < 300
          if response.content.size > 1
            parsed = JSON.parse(response.content).deep_symbolize_keys
          else
            # empty means empty - jira does this =(
            parsed = {}
          end
          return parsed
        end

        # some sort of error may have happened, or it could just be a 404 or something.
        begin
          parsed = JSON.parse(response.content).deep_symbolize_keys
          if status < 500
            raise HttpClientError.new(status, parsed, response.reason)
          else
            raise HttpServerError.new(status, parsed, response.reason)
          end
        rescue Exception => e
          raise e if e.is_a?(HttpBaseStatus)
          raise HttpServerError.new(status, response.content, response.reason)
        end
      end

      # file should be a file handle, not a path
      def json_post_file(path, file, headers = {})
        if !headers['Content-Type']
          headers['Content-Type'] = 'multipart/form-data'
        end
        uri = @endpoint + path

        # TODO: don't hardcode this?
        parameters = { :file => file }

        @log.debug "JSON POST: " + parameters.to_json

        response = raw_post(uri, parameters, headers)

        status = response.status.to_i
        if status >= 200 && status < 300
          if response.content.size > 1
            parsed = JSON.parse(response.content).deep_symbolize_keys
          else
            # empty means empty - jira does this =(
            parsed = {}
          end
          return parsed
        end

        # some sort of error may have happened, or it could just be a 404 or something.
        begin
          parsed = JSON.parse(response.content).deep_symbolize_keys
          if status < 500
            raise HttpClientError.new(status, parsed, response.reason)
          else
            raise HttpServerError.new(status, parsed, response.reason)
          end
        rescue Exception => e
          raise e if e.is_a?(HttpBaseStatus)
          raise HttpServerError.new(status, response.content, response.reason)
        end
      end

      def json_put(path, parameters = {}, headers = {})
        if !headers['Content-Type']
          headers['Content-Type'] = 'application/json'
        end

        uri = @endpoint + path

        @log.debug "JSON PUT: " + parameters.to_json

        response = raw_put(uri, parameters.to_json, headers)

        status = response.status.to_i
        if status >= 200 && status < 300
          if response.content.size > 1
            parsed = JSON.parse(response.content).deep_symbolize_keys
          else
            # empty means empty - jira does this =(
            parsed = {}
          end
          return parsed
        end

        # some sort of error may have happened, or it could just be a 404 or something.
        begin
          parsed = JSON.parse(response.content).deep_symbolize_keys
          if status < 500
            raise HttpClientError.new(status, parsed, response.reason)
          else
            raise HttpServerError.new(status, parsed, response.reason)
          end
        rescue Exception => e
          raise e if e.is_a?(HttpBaseStatus)
          raise HttpServerError.new(status, response.content, response.reason)
        end
      end

      def json_delete(path, parameters = {}, headers = {})
        if !headers['Content-Type']
          headers['Content-Type'] = 'application/json'
        end

        uri = @endpoint + path

        @log.debug "JSON DELETE: " + parameters.to_s

        response = raw_delete(uri, parameters, headers)

        status = response.status.to_i
        if status >= 200 && status < 300
          if response.content.size > 1
            parsed = JSON.parse(response.content).deep_symbolize_keys
          else
            # empty means empty - jira does this =(
            parsed = {}
          end
          return parsed
        end

        # some sort of error may have happened, or it could just be a 404 or something.
        begin
          parsed = JSON.parse(response.content).deep_symbolize_keys
          if status < 500
            raise HttpClientError.new(status, parsed, response.reason)
          else
            raise HttpServerError.new(status, parsed, response.reason)
          end
        rescue Exception => e
          raise e if e.is_a?(HttpBaseStatus)
          raise HttpServerError.new(status, response.content, response.reason)
        end
      end

      def file_get(uri, filepath, parameters = {}, headers = {})

        @log.debug "GET URI: " + uri
        @log.debug "WRITING FILE: " + filepath

        File.open(filepath, 'wb') do |file|
          @raw_http_client.get_content(uri, parameters, @extra_headers.merge(headers)) do |chunk|
            file.write(chunk)
          end
        end
      end

#      # cookie support
#      # NAME: JSESSIONID
#      # example value: A91BB8E0084CBD2B3AD66A910678CDF9
#      def init_cookie
#        # see if a cookie is already stored
#        if File.readable?(CLIENT_COOKIE_FILE)
#          begin
#            File.open(CLIENT_COOKIE_FILE, 'r') do |f|
#              cookie_name = 'JSESSIONID'
#              cookie_value = f.readline.chomp
#              cookie = WebAgent::Cookie.new()
#              cookie.url = ''
#              cookie.domain = ''
#              cookie.name = 'JSESSIONID'
#              cookie.use = true
#              cookie.secure = @endpoint.match(/^https/)
#            end
#          end
#        end
#
#        @raw_http_client.cookie_manager.add(cookie)
#      end

      def test_auth()
        raise "subclass must implement test_cookie to return true or false if login successful"
      end

    end
  end
end
