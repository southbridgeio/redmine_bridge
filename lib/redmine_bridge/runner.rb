class RedmineBridge::Runner
  include Singleton

  def initialize(logger: ActiveSupport::Logger.new("log/runner_#{Rails.env}.log"))
    @logger = logger
    @runner_threads = {}
  end

  def start_runners
    BridgeIntegration.find_each do |integration|
      klass = RedmineBridge::Registry[integration.connector_id].call(integration: integration).runner
      runner_threads[integration.id] = klass.new(integration: integration, logger: logger).run if klass
    end
  end

  def stop_runners
    runner_threads.each_value do |thread|
      Thread.kill(thread) && thread.join
    end
  end

  def restart_runners
    stop_runners && start_runners
  end

  private

  attr_reader :runner_threads, :logger
end
