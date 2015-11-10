require 'optparse'

require 'joumae'

module Joumae
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def parse!
      opt = OptionParser.new
      opt.on('--resource-name VALUE') { |v| @resource_name = v }
      opt.parse!(@argv.dup)
      @cmd, = argv
    end

    def run!
      parse!

      client = Joumae::Client.create
      command = Joumae::Command.new(@cmd, resource_name: @resource_name, client: client)
      command.run
    end

    def self.run!
      new(ARGV).run!
    end
  end
end
