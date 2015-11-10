module Joumae
  module Logging
    protected

    def info(msg)
      logger.info msg
    end

    def warn(msg)
      logger.warn msg
    end

    def debug(msg)
      logger.debug msg
    end

    def logger
      @logger ||= Logger.new(STDOUT).tap do |logger|
        log_level_from_env = ENV['JOUMAE_LOG_LEVEL'] || 'INFO'
        logger.level = Logger.const_get(log_level_from_env)
      end
    end
  end
end
