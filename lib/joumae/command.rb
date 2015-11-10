require 'joumae/transaction'
require 'joumae/client'
require 'open3'

module Joumae
  class Command
    attr_reader :cmd

    def initialize(cmd, resource_name:, client:)
      @cmd = cmd
      @resource_name = resource_name
      @client = client
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def info(msg)
      logger.info msg
    end

    def warn(msg)
      logger.warn msg
    end

    def run
      Joumae::Transaction.run(resource_name: @resource_name, client: @client) do
        Open3.popen3("bash") do |i, o, e, w|
          i.write cmd
          i.close
          o.each do |line| info line end
          e.each do |line| warn line end
          info w.value
        end
      end
    end
  end
end
