class RedmineBridge::Connector
  class << self
    def run_services
      BridgeIntegration.find_each do |integration|
        RedmineBridge::Registry[integration.connector_id].call(integration: integration).run_service
      end
    end
  end

  def run_service
    # TODO
  end
end
