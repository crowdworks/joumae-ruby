require 'optparse'

require 'joumae'
require "joumae/logging"

module Joumae
  class CLI
    include Logging

    def initialize(argv)
      @argv = argv
    end

    def parse!
      argv = @argv.dup

      opt = OptionParser.new
      opt.on('--resource-name VALUE') { |v| @resource_name = v }
      opt.parse!(argv)
      @sub, *@args= argv
      debug [@sub, @args]
    end

    def run!
      parse!

      case @sub
      when "run"
        client = Joumae::Client.create
        cmd = @args.join(" ")
        command = Joumae::Command.new(cmd, resource_name: @resource_name, client: client)
        begin
          command.run!
        rescue Joumae::CommandFailedError => e
          $stderr.puts "#{e.message} Aborting."
          exit e.status
        rescue Joumae::Client::ResourceAlreadyLockedError => e
          $stderr.puts "#{e.message} Aborting."
          exit 1
        end
      else
        fail "The sub-command #{@sub} does not exist."
      end
    end

    def self.run!
      new(ARGV).run!
    end
  end
end
