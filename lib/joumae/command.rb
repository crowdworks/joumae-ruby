require 'joumae/transaction'
require 'joumae/client'
require "joumae/command_failed_error"
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
      @logger ||= Logger.new(STDOUT).tap do |logger|
        log_level_from_env = ENV['JOUMAE_LOG_LEVEL'] || 'INFO'
        logger.level = Logger.const_get(log_level_from_env)
        logger.formatter = proc do |severity, datetime, progname, msg|
          date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
          "#{cmd} (#{severity}): #{msg}\n"
        end
      end
    end

    def run!
      status = Joumae::Transaction.run!(resource_name: @resource_name, client: @client) do
        Open3.popen3("bash") do |i, o, e, w|
          i.write cmd
          i.close

          o.each do |line|
            STDOUT.puts line
            STDOUT.flush
          end

          e.each do |line|
            STDERR.puts line
            STDERR.flush
          end

          debug w.value

          w.value.exitstatus
        end
      end
      raise Joumae::CommandFailedError.new("Exit status(=#{status}) is non-zero.", status) if status != 0
    end

    private

    def info(msg)
      logger.info msg
    end

    def warn(msg)
      logger.warn msg
    end

    def debug(msg)
      logger.debug msg
    end
  end
end
