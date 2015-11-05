require 'net/https'
require 'logger'
require 'json'

module Joumae
  class Client
    attr_reader :api_endpoint
    attr_reader :api_key

    def self.create(api_endpoint: nil, api_key: nil)
      new(api_endpoint: api_endpoint || ENV['JOUMAE_API_ENDPOINT'], api_key: api_key || ENV['JOUMAE_API_KEY'])
    end

    def initialize(api_endpoint:, api_key:)
      @api_endpoint = api_endpoint
      @api_key = api_key
    end

    def create(name)
      post_json(resources_url, {api_key: api_key, name: name})
    end

    def acquire(name, acquired_by)
      post_json(acquire_resource_url, {api_key: api_key, name: name, acquiredBy: acquired_by})
    end

    def renew(name, acquired_by)
      post_json(renew_resource_url, {api_key: api_key, name: name, acquired_by: acquired_by})
    end

    def release(name, acquired_by)
      post_json(release_resource_url, {api_key: api_key, name: name, acquired_by: acquired_by})
    end

    def post_json(url, params={})
      begin
        logger.info "POST #{url} #{params.to_json}"
        request = Net::HTTP::Post.new(url.path, {'Content-Type' =>'application/json'})
        request.body = params.to_json
        https = Net::HTTP.new(url.hostname, 443)
        https.use_ssl = true
        response = https.start do
          https.request(request)
        end
        # response = httpclient.post_content(url, params.to_json, header: {'Content-Type' => 'application/json'})

        if response.code == '404'
          fail "Not found."
        elsif response.code != '200'
          fail "Unexpected status: #{response.code}"
        end

        response_body = JSON.parse(response.body)
        response_body
      rescue => e
        logger.debug "Dumping HTTP response:\n#{response.inspect} #{response.body}"
        fail e
      end
    end

    def resources_url
      URI.parse("#{api_endpoint}/resources")
    end

    def acquire_resource_url
      URI.parse("#{api_endpoint}/resources/acquire")
    end

    def renew_resource_url
      URI.parse("#{api_endpoint}/resources/renew")
    end

    def release_resource_url
      URI.parse("#{api_endpoint}/resources/release")
    end

    def httpclient
      @httpclient ||= HTTPClient.new
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
