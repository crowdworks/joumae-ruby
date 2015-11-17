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
          redirect(STDIN => i, o => STDOUT, e => STDERR)

          debug w.value

          w.value.exitstatus
        end
      end
      raise Joumae::CommandFailedError.new("Exit status(=#{status}) is non-zero.", status) if status != 0
    end

    private

    def redirect(mapping)
      inputs = mapping.keys
      ios_ready_for_eof_check = []

      debug "Joumae::Command#redirect: mapping: " + mapping.inspect

      # Calling IO#eof against an IO which is not `select`ed previous blocks the current thread.
      # So you can't do something like :
      #   until inputs.all?(&:eof) do
      # Or:
      #   until (inputs - [STDIN]).all?(&:eof) do
      until inputs.empty? || (inputs.size == 1 && inputs.first == STDIN) do
        debug 'starting `select`'

        readable_inputs, = IO.select(inputs, [], [], 1)
        ios_ready_for_eof_check = readable_inputs

        debug 'finished `select`'

        # We can safely call `eof` without blocking against previously selected IOs.
        debug 'starting eof check'
        ios_ready_for_eof_check.select(&:eof).each do |src|
          debug "Stopping redirection from an IO in EOF: " + src.inspect
          # `select`ing an IO which has reached EOF blocks forever.
          # So you have to delete such IO from the array of IOs to `select`.
          inputs.delete src

          # You must close the child process' STDIN immeditely after the parent's STDIN reached EOF,
          # or some kinds of child processes never exit.
          # e.g.) echo foobar | joumae run -- cat
          # After the `echo` finished outputting `foobar`, you have to tell `cat` about that or `cat` will wait for more inputs forever.
          mapping[src].close if src == STDIN
        end

        break if inputs.empty? || (inputs.size == 1 && inputs.first == STDIN)

        readable_inputs.each do |input|
          begin
            data = input.read_nonblock(1024)
            output = mapping[input]
            output.write(data)
            output.flush
          rescue EOFError => e
            debug "Reached EOF: #{e}"
            inputs.delete input
          rescue Errno::EPIPE => e
            # How to produce this error:
            # 1. Run the command:
            #   cat | bin/joumae run --resource-name test -- bundle exec ruby -v
            # 2. Press Enter several times
            debug "Handled error: #{e}: io: #{input.inspect}"
            inputs.delete input
          end
        end

        ios_ready_for_eof_check = inputs & readable_inputs
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
