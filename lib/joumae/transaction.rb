module Joumae
  class Transaction
    def initialize(resource_name:, client:, renew_interval: 20, ttl: 30)
      @resource_name = resource_name
      @client = client
      @renew_interval = renew_interval
      @ttl = ttl
      @finished = false
    end

    def start
      @client.acquire(@resource_name, ttl: @ttl)

      start_thread
    end

    def start_thread
      fail "Thread already started" if @thread

      @thread = Thread.start {
        loop do
          wait_started_time = Time.now
          while Time.now - wait_started_time < @renew_interval
            sleep 0.1
            @thread.exit if finished?
          end
          @client.renew(@resource_name, ttl: @ttl)
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

    def self.run!(resource_name:, client:, &block)
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
