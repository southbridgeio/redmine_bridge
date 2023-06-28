class RedmineBridge::IssueRepository
  def initialize(integration)
    @integration = integration
  end

  def create(external_attributes, **params)
    status_id = integration.statuses.reject { |_k, v| v.blank? }.invert[external_attributes.status_id.to_s]
    priority_id = integration.priorities.reject { |_k, v| v.blank? }.invert[external_attributes.priority_id.to_s]

    # if we got external webhook about creation, but after we've created issue in redmine first
    external_issue = integration.external_issues.find_by(external_id: external_attributes.id,
                                                         connector_id: connector_id)
    return if external_issue

    issue =
      ActiveRecord::Base.transaction do
        issue = Issue.create!(params.merge(status_id: status_id, priority_id: priority_id).compact)
        ExternalIssue.create!(redmine_id: issue.id,
                              connector_id: connector_id,
                              external_id: external_attributes.id,
                              bridge_integration: integration,
                              external_url: external_attributes.url)
        issue
      end
    broadcast_issue_created(issue)
  end

  def update(external_attributes, **params)
    external_issue =
      if connector_id == 'jira'
        integration.external_issues.find_by(external_id: external_attributes.id, connector_id: connector_id)
      else
        # TODO: we need to find these issue from integration too. But to do that we need to update database
        ExternalIssue.find_by(external_id: external_attributes.id, connector_id: connector_id)
      end

    issue = external_issue&.redmine_issue

    return unless issue

    status_id = integration.statuses.reject { |_k, v| v.blank? }.invert[external_attributes.status_id.to_s]
    priority_id = integration.priorities.reject { |_k, v| v.blank? }.invert[external_attributes.priority_id.to_s]

    journal = issue.init_journal(User.anonymous)
    issue.assign_attributes(params.merge(status_id: status_id, priority_id: priority_id).compact)

    return unless issue.changed?

    issue.save!

    broadcast_issue_updated(issue, journal)
  end

  # Is keeped to compatibility with prometheus
  def add_notes(external_id, notes)
    issue = ExternalIssue.find_by(external_id: external_id, connector_id: connector_id)&.redmine_issue
    return unless issue

    journal = issue.init_journal(User.anonymous, notes)
    issue.save!

    broadcast_issue_updated(issue, journal)
  end

  def add_or_update_comment(issue_id, comment_id, notes)
    if issue_id.blank? || comment_id.blank?
      Rails.logger.warn "Issue id: #{issue_id} or comment id: #{comment_id} is blank"
      return
    end

    issue = integration.external_issues.find_by(external_id: issue_id, connector_id: connector_id)&.redmine_issue
    return unless issue

    external_comment = integration.external_comments.find_or_create_by(external_id: comment_id, connector_id: connector_id)
    comment = external_comment.redmine_journal

    if comment
      unless comment.user.nil? || comment.user.anonymous?
        # Don't change comments from redmine users by hooks. They happen in the case:
        # Create comment in redmine. It creates comment in Jira. Webhook comes from jira
        # about comment creation.
        return
      end

      comment.notes = notes
    else
      comment = issue.init_journal(User.anonymous, notes)
      external_comment.redmine_journal = comment
    end
    comment.save!
    external_comment.save!
  end

  private

  attr_reader :integration

  def broadcast_issue_created(issue)
    bridge_integrations = BridgeIntegration.where(project_id: integration.project_id)
    # делаем broadcast только в jira, т.к. gitlab ждет апдейтов только у своих ишьюсов
    bridge_integrations
      .select { |bi| bi.connector_id == 'jira' }
      .select { |bi| bi.id != integration.id }.each do |bi|
        external_issue = bi.external_issues.create!(redmine_id: issue.id, connector_id: bi.connector_id)
        RedmineBridge::IssueCreateJob.perform_later(bi, external_issue)
      end
  end

  def broadcast_issue_updated(issue, journal)
    bridge_integrations = BridgeIntegration.where(project_id: integration.project_id)
    # делаем broadcast только в jira, т.к. gitlab ждет апдейтов только у своих ишьюсов
    bridge_integrations
      .select { |bi| bi.connector_id == 'jira' }
      .select { |bi| bi.id != integration.id }.each do |bi|
        external_issue = ExternalIssue.find_by(redmine_id: issue.id, connector_id: bi.connector_id)
        next unless external_issue

        RedmineBridge::IssueUpdateJob.perform_later(bi, external_issue, journal)
      end
  end

  def connector_id
    integration.connector_id
  end
end
