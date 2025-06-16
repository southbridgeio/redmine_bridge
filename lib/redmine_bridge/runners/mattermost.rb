class RedmineBridge::Runners::Mattermost
  RECONNECT_TIME = 10

  def initialize(integration:, logger: Rails.logger)
    @logger = logger
    @integration = integration
    @settings = integration.settings
  end

  def run
    return unless valid?

    Thread.new do
      I18n.locale = settings['mattermost_locale'] || 'en'
      loop do
        logger.debug [:em_run, integration.name]
        EM.run do
          url = "#{Setting.protocol == 'https' ? 'wss' : 'ws'}://#{settings['mattermost_api_url']}/api/v4/websocket"
          ws = Faye::WebSocket::Client.new(url, [], headers: { 'Origin' => Setting.host_name })

          ws.onopen = lambda do |event|
            logger.debug [:ws_open, ws.headers]
            ws.send(
              {
                seq: 1,
                action: 'authentication_challenge',
                data: {
                  token: settings['mattermost_access_token']
                }
              }.to_json
            )
          end

          ws.onclose = lambda do |close|
            logger.debug [:ws_close, close.code, close.reason]
            EM.stop
          end

          ws.onerror = lambda do |error|
            logger.debug [:ws_error, error.message]
          end

          ws.onmessage = lambda do |message|
            logger.debug [:ws_message, message.data]

            data = JSON.parse(message.data)['data']
            post = JSON.parse(data['post']) if data && data['post']
            return if post.nil? || !post['message'].start_with?("@#{settings['mattermost_token_username']}")

            # TODO: Disable debug after problem solve
            logger.error [:post, post]
            params = {
              'channel_id' => post['channel_id'],
              'post_id' => post['id'],
              'root_id' => post['root_id'],
              'user_id' => post['user_id'],
              'text' => post['message'].strip
            }
            RedmineBridge::WebhookJob.set(wait: 3.seconds).perform_later(integration, params)
          end
        end
        logger.debug [:em_stop, integration.name]
        sleep RECONNECT_TIME
      end
      logger.error "Thread for #{integration.name} stopped"
    end
  end

  private

  attr_reader :logger, :integration, :settings

  def valid?
    [settings['mattermost_api_url'], settings['mattermost_access_token']].all?(&:present?)
  end
end
