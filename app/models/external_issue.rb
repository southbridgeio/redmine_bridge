class ExternalIssue < ActiveRecord::Base
  include AASM
  # TODO: add paper_trail? or audited. Or we should make journals?

  belongs_to :redmine_issue, foreign_key: 'redmine_id', class_name: 'Issue'
  # TODO: optional because it's used only in JIRA for now
  # We need bridge_integration, because we have only external_id from outside - and it
  # could be the same for different redmine issues in different projects
  belongs_to :bridge_integration, foreign_key: 'bridge_integration_id', class_name: 'BridgeIntegration', optional: true

  aasm column: 'state' do
    state :pending, initial: true
    state :syncing
    state :synced
    state :skipped
    state :failed

    event :sync do
      transitions to: :syncing
    end

    event :done_sync do
      transitions from: :syncing, to: :synced
    end

    event :skip do
      transitions from: [:pending, :syncing], to: :skipped
    end

    event :fail do
      transitions to: :failed
    end
  end
end
