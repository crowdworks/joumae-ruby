module Joumae
  class Transaction
    def initialize(resource_name:, client:, renew_interval: 1)
      @resource_name = resource_name
      @client = client
      @renew_interval = renew_interval
      @finished = false
    end

    def start
      @client.acquire(@resource_name)

      start_thread
    end

    def start_thread
      fail "Thread already started" if @thread

      @thread = Thread.start {
        loop do
          sleep @renew_interval
          @thread.exit if finished?
          @client.renew(@resource_name)
        end
      }
    end

    def stop_thread
      @finished = true

      @thread.join
    end

    def finish
      stop_thread
      @client.release(@resource_name)
    end

    def finished?
      @finished
    end

    def self.run(resource_name:, client:, &block)
      t = new(resource_name: resource_name, client: client)
      t.start
      begin
        block.call
      ensure
        t.finish
      end
    end
  end
end
