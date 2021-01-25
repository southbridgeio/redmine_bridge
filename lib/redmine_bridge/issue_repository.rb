class RedmineBridge::IssueRepository
  def initialize(integration)
    @integration = integration
  end

  def create(external_attributes, **params)
    status_id = integration.statuses.invert[external_attributes.status_id.to_s]
    priority_id = integration.priorities.invert[external_attributes.priority_id.to_s]


    ActiveRecord::Base.transaction do
      issue = Issue.create!(params.merge(status_id: status_id, priority_id: priority_id).compact)
      ExternalIssue.create!(redmine_id: issue.id,
                            connector_id: connector_id,
                            external_id: external_attributes.id,
                            external_url: external_attributes.url)
    end
  end

  def update(external_attributes, **params)
    issue = ExternalIssue.find_by(external_id: external_attributes.id, connector_id: connector_id)&.redmine_issue
    return unless issue

    status_id = integration.statuses.invert[external_attributes.status_id.to_s]
    priority_id = integration.priorities.invert[external_attributes.priority_id.to_s]

    issue.init_journal(User.anonymous)
    issue.assign_attributes(params.merge(status_id: status_id, priority_id: priority_id).compact)
    issue.save!
  end

  def add_notes(external_id, notes)
    issue = ExternalIssue.find_by(external_id: external_id, connector_id: connector_id)&.redmine_issue
    return unless issue

    issue.init_journal(User.anonymous, notes)
    issue.save!
  end

  private

  attr_reader :integration

  def connector_id
    integration.connector_id
  end
end
