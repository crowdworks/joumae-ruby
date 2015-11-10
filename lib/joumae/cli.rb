require 'optparse'

require 'joumae'

module Joumae
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def parse!
      argv = @argv.dup

      opt = OptionParser.new
      opt.on('--resource-name VALUE') { |v| @resource_name = v }
      opt.parse!(argv)
      @sub, *@args= argv
      p @sub, @args
    end

    def run!
      parse!

      case @sub
      when "run"
        client = Joumae::Client.create
        cmd = @args.join(" ")
        command = Joumae::Command.new(cmd, resource_name: @resource_name, client: client)
        command.run!
      else
        fail "The sub-command #{@sub} does not exist."
      end
    end

    def self.run!
      new(ARGV).run!
    end
  end
end
