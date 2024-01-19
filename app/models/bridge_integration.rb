# frozen_string_literal: true

# Integration model
class BridgeIntegration < ActiveRecord::Base
  belongs_to :project

  has_many :external_issues, dependent: :destroy
  has_many :external_comments, dependent: :destroy

  store :settings, accessors: %i[statuses priorities]

  validates :name,
            :key,
            :connector_id,
            :project_id,
            :statuses,
            :priorities, presence: true

  validates :key, uniqueness: true, if: Proc.new { |integration| integration.connector_id.in?(%w[jira gitlab]) }
  validate :prometheus_bridge_integration_uniqueness, if: Proc.new { |integration| integration.connector_id == 'prometheus' }

  private

  # We allow multiple prometheus integrations with same key, but keys should be uniq for other connectors
  def prometheus_bridge_integration_uniqueness
    if BridgeIntegration.find_by("key = ? AND connector_id != ?", key, 'prometheus')
      errors.add(:base, l('redmine_bridge.errors.prometheus_key_uniqueness'))
    end
  end
end
