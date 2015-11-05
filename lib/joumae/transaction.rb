module Joumae
  class Transaction
    def initialize(resource_name:, owner:, client:, renew_interval: 1)
      @resource_name = resource_name
      @owner = owner
      @client = client
      @renew_interval = renew_interval
      @finished = false
    end

    def start
      @client.acquire(@resource_name, @owner)

      start_thread
    end

    def start_thread
      fail "Thread already started" if @thread

      @thread = Thread.start {
        loop do
          sleep @renew_interval
          exit if finished?
          @client.renew(@resource_name, @owner)
        end
      }
    end

    def stop_thread
      @finished = true

      @thread.join
    end

    def finish
      stop_thread
      @client.release(@resource_name, @owner)
    end

    def finished?
      @finished
    end
  end
end
