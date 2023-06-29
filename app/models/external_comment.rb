class ExternalComment < ActiveRecord::Base
  include AASM

  belongs_to :redmine_journal, foreign_key: 'redmine_id', class_name: 'Journal'
  belongs_to :external_issue, foreign_key: 'external_issue_id', class_name: 'ExternalIssue'
  # TODO: optional because it's used only in JIRA for now
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
