class RedmineBridge::IssueRepository
  def initialize(integration)
    @integration = integration
  end

  def create(external_id, external_url, **params)
    ActiveRecord::Base.transaction do
      issue = Issue.create!(params)
      ExternalIssue.create!(redmine_id: issue.id,
                            connector_id: connector_id,
                            external_id: external_id,
                            external_url: external_url)
    end
  end

  def update(external_id, **params)
    issue = ExternalIssue.find_by(external_id: external_id, connector_id: connector_id)&.redmine_issue
    return unless issue

    issue.init_journal(User.anonymous)
    issue.assign_attributes(params)
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
