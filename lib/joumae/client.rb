require 'net/https'
require 'logger'
require 'json'

module Joumae
  class Client
    attr_reader :api_endpoint
    attr_reader :api_key

    def self.create(api_endpoint: nil, api_key: nil, ttl: 15)
      new(
        api_endpoint: api_endpoint || ENV['JOUMAE_API_ENDPOINT'],
        api_key: api_key || ENV['JOUMAE_API_KEY'],
	ttl: ttl
      )
    end

    def initialize(api_endpoint:, api_key:, ttl:)
      @api_endpoint = api_endpoint
      @api_key = api_key
      @ttl = ttl
    end

    def create(name)
      post_json(resources_url, {api_key: api_key, name: name})
    end

    def acquire(name, ttl: nil)
      params = {api_key: api_key, ttl: ttl || @ttl}
      post_json(acquire_resource_url(name), params)
    end

    def renew(name, ttl: nil)
      params = {api_key: api_key, ttl: ttl || @ttl}
      post_json(renew_resource_url(name), params)
    end

    def release(name)
      post_json(release_resource_url(name), {api_key: api_key})
    end

    def post_json(url, params={})
      begin
        debug "POST #{url} #{params.to_json}"
        request = Net::HTTP::Post.new(url.path, {'Content-Type' =>'application/json'})
        request.body = params.to_json
        https = Net::HTTP.new(url.hostname, 443)
        https.use_ssl = true
        response = https.start do
          https.request(request)
        end
        # response = httpclient.post_content(url, params.to_json, header: {'Content-Type' => 'application/json'})

        if response.code == '404'
          fail ResourceNotFoundError, "Not found."
        elsif response.code == '423'
          response_body_as_json = JSON.parse(response.body)
          raise ResourceAlreadyLockedError, response_body_as_json["message"]
        elsif response.code != '200'
          fail UnexpectedError, "Unexpected status: #{response.code}"
        end

        debug "Code: #{response.code}"
        debug "Result: #{response.body}"

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

    def acquire_resource_url(name)
      URI.parse("#{api_endpoint}/resources/#{name}/lock/acquire")
    end

    def renew_resource_url(name)
      URI.parse("#{api_endpoint}/resources/#{name}/lock/renew")
    end

    def release_resource_url(name)
      URI.parse("#{api_endpoint}/resources/#{name}/lock/release")
    end

    protected

    def debug(msg)
      logger.debug msg
    end

    private

    def httpclient
      @httpclient ||= HTTPClient.new
    end

    def logger
      @logger ||= Logger.new(STDOUT).tap do |logger|
        log_level_from_env = ENV['JOUMAE_LOG_LEVEL'] || 'INFO'
        logger.level = Logger.const_get(log_level_from_env)
      end
    end

    class ResourceAlreadyLockedError < StandardError
    end

    class ResourceNotFoundError < StandardError
    end

    class UnexpectedError < StandardError
    end
  end
end
