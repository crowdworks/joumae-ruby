module Joumae
  class CommandFailedError < StandardError
    attr_reader :status

    def initialize(msg, status)
      super(msg)
      @status = status
    end
  end
end
