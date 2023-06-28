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

    ActiveRecord::Base.transaction do
      issue = Issue.create!(params.merge(status_id: status_id, priority_id: priority_id).compact)
      ExternalIssue.create!(redmine_id: issue.id,
                            connector_id: connector_id,
                            external_id: external_attributes.id,
                            bridge_integration: integration,
                            external_url: external_attributes.url)
    end
  end

  def update(external_attributes, **params)
    issue =
      if connector_id == 'jira'
        integration.external_issues.find_by(external_id: external_attributes.id, connector_id: connector_id)&.redmine_issue
      else
        # TODO: we need to find these issue from integration too. But to do that we need to update database
        ExternalIssue.find_by(external_id: external_attributes.id, connector_id: connector_id)&.redmine_issue
      end

    return unless issue

    status_id = integration.statuses.reject { |_k, v| v.blank? }.invert[external_attributes.status_id.to_s]
    priority_id = integration.priorities.reject { |_k, v| v.blank? }.invert[external_attributes.priority_id.to_s]

    issue.init_journal(User.anonymous)
    issue.assign_attributes(params.merge(status_id: status_id, priority_id: priority_id).compact)

    return unless issue.changed?

    issue.save!
  end

  # Is keeped to compatibility with prometheus
  def add_notes(external_id, notes)
    issue = ExternalIssue.find_by(external_id: external_id, connector_id: connector_id)&.redmine_issue
    return unless issue

    issue.init_journal(User.anonymous, notes)
    issue.save!
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

  def connector_id
    integration.connector_id
  end
end
