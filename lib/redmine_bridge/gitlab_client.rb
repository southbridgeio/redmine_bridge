class RedmineBridge::GitlabClient
  def initialize(base_url:, access_token:)
    @base_url = base_url
    @access_token = access_token
  end

  def update_issue(project_id, issue_iid, **params)
    RestClient.put(File.join(base_url, 'api', 'v4', 'projects', project_id, 'issues', issue_iid), params, headers)
  end

  def create_discussion(project_id, issue_iid, **params)
    RestClient.post(File.join(base_url, 'api', 'v4', 'projects', project_id, 'issues', issue_iid, 'discussions'), params, headers)
  end

  private

  attr_reader :access_token, :base_url

  def headers
    { Authorization: "Bearer #{access_token}" }
  end
end
