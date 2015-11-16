require 'joumae/transaction'
require 'joumae/client'
require "joumae/command_failed_error"
require 'open3'

module Joumae
  class Command
    EXIT_STATUS_INTERRUPT = 130

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
        Open3.popen3(cmd) do |i, o, e, w|
          unless STDIN.tty?
            redirect(STDIN => i)
          end
          i.close

          redirect(o => STDOUT, e => STDERR)

          debug w.value

          w.value.exitstatus
        end
      end
      raise Joumae::CommandFailedError.new("Exit status(=#{status}) is non-zero.", status) if status != 0
    end

    private

    def redirect(mapping)
      files = mapping.keys

      until files.all?(&:eof) do
        ready = IO.select(files)

        continue unless ready

        readable = ready[0]

        readable.each do |f|
          begin
            data = f.read_nonblock(1024)

            mapping[f].write(data)
            mapping[f].flush
          rescue EOFError => e
            debug e.to_s;
          end
        end
      end
    end

    def all_eof?(files)
      begin
        files.all?(&:eof)
      rescue Interrupt => e
        warn "You've interrupted while joumae is running a command."
        EXIT_STATUS_INTERRUPT
      end
    end

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
