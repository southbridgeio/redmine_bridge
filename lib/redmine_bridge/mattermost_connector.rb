class RedmineBridge::MattermostConnector
  def initialize(logger: Rails.logger, integration:)
    @logger = logger
    @integration = integration
    @settings = integration.settings
  end

  def valid_for?(params)
    (%w[team_id channel_id post_id text] - params.keys).empty?
  end

  def on_issue_update(*)
    # TODO
  end

  def on_issue_create(*)
    # TODO
  end

  def on_comment_create(*)
    # TODO
  end

  def on_comment_update(*)
    # TODO
  end

  def check_connection
    raise NotImplementedError
  end

  def on_webhook_event(params:, issue_repository:)
    project = integration.project
    tracker = project.trackers.find_by(id: settings['mattermost_default_tracker_id']) || project.trackers.first
    status_id = settings['mattermost_default_status_id'] || tracker.issue_statuses.first.id
    priority_id = settings['mattermost_default_priority_id'] || IssuePriority.active.default.id

    command, data, extra = parse_command(params)
    return unless command

    case command.downcase
    when 'задача', 'задача:', 'issue', 'issue:'
      issue = Issue.create!(project: project,
                            tracker: tracker,
                            status_id: status_id,
                            priority_id: priority_id,
                            subject: data,
                            description: build_description(params['post_id'], extra),
                            author: User.anonymous)

      ::RedmineBridge::MattermostClient.new(settings, params).issue_created(issue)
    end
  end

  private

  attr_reader :logger, :integration, :settings

  def parse_command(params)
    lines = params['text'].split("\n")

    command, data = lines[0].match(/^@\S+\s+(\S+)\s+(.+)$/).to_a[1..-1]

    [command, data, lines[1..-1].join("\n")]
  end

  def build_description(post_id, extra)
    post_url = settings['mattermost_api_url'] + "/" + settings['mattermost_team_id'] + "/pl/" + post_id

    "*#{I18n.t('redmine_bridge.integration.mattermost.initial_message')}*: #{post_url}\n\n#{extra}"
  end
end
