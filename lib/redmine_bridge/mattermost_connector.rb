class RedmineBridge::MattermostConnector
  RECONNECT_TIME = 5

  ACCIDENT_PRIORITY = 14

  def initialize(integration:, logger: Rails.logger)
    @logger = logger
    @integration = integration
    @settings = integration.settings
  end

  def valid_for?(params)
    (%w[team_id channel_id post_id text] - params.keys).empty?
  end

  def runner
    RedmineBridge::Runners::Mattermost
  end

  def on_issue_update(journal:, external_issue:)
    params = {
      'channel_id' => external_issue.external_url,
      'root_id' => external_issue.external_id.split('|').find(&:present?),
    }
    issue = Intouch::IssueDecorator.new(external_issue.redmine_issue, journal.id, protocol: 'mattermost')
    ::RedmineBridge::MattermostClient.new(settings, params).issue_updated(issue)
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

  def on_webhook_event(params:, issue_repository:, test:)
    project = integration.project
    tracker = project.trackers.find_by(id: settings['mattermost_default_tracker_id']) || project.trackers.first
    status_id = settings['mattermost_default_status_id'] || tracker.issue_statuses.first.id
    priority_id = settings['mattermost_default_priority_id'] || IssuePriority.active.default.id

    command, data, extra = parse_command(params)
    return unless command

    issue_attributes = {
      post_id: "#{params['root_id']}|#{params['post_id']}",
      channel_id: params['channel_id'],
      project: project,
      tracker: tracker,
      status_id: status_id,
      priority_id: priority_id,
      data: data,
      description: build_description(params['post_id'], extra)
    }

    case command.downcase
    when 'задача', 'задача:', 'issue', 'issue:'
      ApplicationRecord.transaction do
        issue = create_issue(issue_attributes)

        ::RedmineBridge::MattermostClient.new(settings, params).issue_created(issue)
      end
    when 'авария', 'авария:'
      ApplicationRecord.transaction do
        issue = create_issue(issue_attributes.merge(priority_id: ACCIDENT_PRIORITY))

        ::RedmineBridge::MattermostClient.new(settings, params).issue_created(issue)
      end
    else
      ::RedmineBridge::MattermostClient.new(settings, params).unknown_action
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
    post_url = "#{Setting.protocol}://" + settings['mattermost_api_url'] + "/" + settings['mattermost_team_id'] + "/pl/" + post_id

    "*#{I18n.t('redmine_bridge.integration.mattermost.initial_message')}*: #{post_url}\n\n#{extra}"
  end

  def create_issue(**attrs)
    raise ActiveRecord::Rollback if integration.external_issues.find_by(external_id: attrs[:post_id])

    issue = Issue.create!(project: attrs[:project],
                          tracker: attrs[:tracker],
                          status_id: attrs[:status_id],
                          priority_id: attrs[:priority_id],
                          subject: attrs[:data],
                          description: attrs[:description], #,
                          author: User.anonymous)

    integration.external_issues.create!(external_id: attrs[:post_id],
                                        external_url: attrs[:channel_id],
                                        redmine_issue: issue,
                                        state: :skipped,
                                        connector_id: integration.connector_id)
    issue
  end
end
