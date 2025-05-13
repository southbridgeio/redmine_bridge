module RedmineBridge
  class MattermostClient
    def initialize(settings, params)
      @base_url = settings['mattermost_api_url'] + '/api/v4'
      @access_token = settings['mattermost_access_token']

      @params = params
    end

    def issue_created(issue)
      RestClient.post(File.join("#{Setting.protocol}://", base_url, 'posts'), payload(issue).to_json, headers)
    end

    def unknown_action
      RestClient.post(File.join("#{Setting.protocol}://", base_url, 'posts'), unknown_payload.to_json, headers)
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
