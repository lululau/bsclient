require 'digest'
require 'faraday'
require 'openssl'
require 'base64'

module BSClient
  class App
    attr_accessor :config, :options

    def initialize(options, config)
      @options = options
      @config = config
    end

    def register_account(request)
      post_json(@config.register_url, request)
    end

    def query_registration(task_id, account)
      url = @config.query_url
      request = {
        taskId: task_id,
        account: account
      }.to_json
      params = build_query_params
      params.merge!(sign: sign(url, params, request))
      resp = Faraday.post(url) do |req|
        req.headers[:content_type] = 'application/json; charset=UTF-8'
        req.params = params
        req.body = request
      end
      format_response(resp)
    end

    def create_user_image(request)
      post_json(@config.create_user_image_url, request)
    end

    def download_user_image(params)
      get(@config.download_user_image_url, params)
    end

    def sign(url, params, body = nil)
      body_digest = if body
                      digest_body(body)
                    else
                      ''
                    end
      rsa_sign(build_to_signed(url, params, body_digest))
    end

    def build_query_params(params = {})
      params.merge(developerId: @config.developer_id,
                   rtick: rtick,
                   signType: 'rsa')
    end

    def build_to_signed(url, params, body_digest)
      params = params.sort.map { |kv| kv.join('=') }.join
      path = URI.parse(url).path
      "#{params}#{path}#{body_digest}"
    end

    def rsa_sign(content)
      Base64.strict_encode64(read_private_key.sign(OpenSSL::Digest::SHA1.new, content))
    end

    def read_private_key
      raw_key = File.read(File.expand_path(@config.private_key)).chomp
      key = "-----BEGIN RSA PRIVATE KEY-----\n#{raw_key}\n-----END RSA PRIVATE KEY-----\n"
      OpenSSL::PKey::RSA.new(key)
    end

    def digest_body(body)
      Digest::MD5.hexdigest(body)
    end

    def rtick
      "#{(Time.now.to_f * 10000).to_i}"
    end

    def print_response(resp)
      if options[:verbose]
        print format_response(resp)
      else
        print resp.body
      end
    end

    def get(url, params)
      params = build_query_params(params)
      params.merge!(sign: sign(url, params))
      resp = Faraday.get(url) do |req|
        req.params = params
      end
      format_response(resp)
    end

    def post_json(url, request)
      params = build_query_params
      params.merge!(sign: sign(url, params, request))
      resp = Faraday.post(url) do |req|
        req.headers[:content_type] = 'application/json; charset=UTF-8'
        req.params = params
        req.body = request
      end
      format_response(resp)
    end

    def format_response(resp)
      unless options[:verbose]
        return resp.body
      end
      request_body = if resp.env.request_body.nil?
                       <<-EOF
                         +-------------------------------------------------+
                         |               No Request Body                   |
                         +-------------------------------------------------+
                       EOF
                     elsif resp.env.request_headers['content-type'] =~ /multipart/
                       <<-EOF
                         +-------------------------------------------------+
                         |                   Binary Data                   |
                         +-------------------------------------------------+
                       EOF
                     elsif resp.env.request_headers['content-type'] =~ /json/
                       json = JSON.pretty_generate(JSON.parse(resp.env.request_body))
                       json.gsub(/^/, '  ')
                     else
                       resp.env.request_body
                     end
      response_body = if resp.env.response_headers['content-type'] =~ /json/
                       json = JSON.pretty_generate(JSON.parse(resp.env.response_body))
                       json.gsub(/^/, '  ')
                     elsif resp.env.response_headers['content-type'] =~ /text/
                       resp.env.response_body
                     else
                       <<-EOF
                         +-------------------------------------------------+
                         |                   Binary Data                   |
                         +-------------------------------------------------+
                       EOF
                    end
      <<~EOF

        Request Method: #{resp.env.method.to_s.upcase}
        ----------------------

        URL: #{resp.env.url}
        ----------------------

        Request Headers:
        ----------------

        #{resp.env.request_headers.map { |k, v| "  #{k}: #{v}" }.join("\n")}

        Request Body:
        -------------
        #{request_body}

        ============================================

        Response Status: #{resp.status} #{resp.reason_phrase}
        ----------------------

        Response Headers:
        ----------------
        #{resp.env.response_headers.map { |k, v| "  #{k}: #{v}" }.join("\n")}

        Response Body:
        ----------------
        #{response_body}
      EOF
    end
  end
end
