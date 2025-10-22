module RedmineBridge
  class MattermostClient
    def initialize(settings, params)
      @base_url = settings['mattermost_api_url'] + '/api/v4'
      @access_token = settings['mattermost_access_token']

      @params = params
    end

    def issue_created(issue)
      RestClient.post(File.join("#{Setting.protocol}://", base_url, 'posts'), payload(issue).to_json, headers)
    rescue RestClient::InternalServerError
      Rails.logger.error("RedmineBridge::MattermostClient#issue_created RestClient error: #{payload(issue)}")
    end

    def issue_updated(issue)
      RestClient.post(File.join("#{Setting.protocol}://", base_url, 'posts'), updated_payload(issue).to_json, headers)
    rescue RestClient::InternalServerError
      Rails.logger.error("RedmineBridge::MattermostClient#issue_updated RestClient error: #{updated_payload(issue)}")
    end

    def unknown_action
      RestClient.post(File.join("#{Setting.protocol}://", base_url, 'posts'), unknown_payload.to_json, headers)
    rescue RestClient::InternalServerError
      Rails.logger.error("RedmineBridge::MattermostClient#unknown_action RestClient error: #{unknown_payload}")
    end

    def get_channel(channel_id)
      RestClient.get(File.join("#{Setting.protocol}://", base_url, 'channels', channel_id), headers)
    end

    def get_post(post_id)
      RestClient.get(File.join("#{Setting.protocol}://", base_url, 'posts', post_id), headers)
    end

    private

    attr_reader :base_url, :access_token, :params

    def payload(issue)
      issue_url = "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue.id}"
      {
        channel_id: params['channel_id'],
        message: I18n.t('redmine_bridge.integration.mattermost.issue_created', id: issue.id, url: issue_url),
        root_id: params['root_id'].presence || params['post_id'],
      }
    end

    def updated_payload(issue)
      {
        channel_id: params['channel_id'],
        message: issue.as_markdown,
        root_id: params['root_id'].presence || params['post_id'],
      }
    end

    def unknown_payload
      {
        channel_id: params['channel_id'],
        message: I18n.t('redmine_bridge.integration.mattermost.unknown_action'),
        root_id: params['root_id'].presence || params['post_id'],
      }
    end

    def headers
      {
        content_type: :json,
        Authorization: "Bearer #{access_token}"
      }
    end
  end
end
