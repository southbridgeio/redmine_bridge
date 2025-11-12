# frozen_string_literal: true

# Integration model
class BridgeIntegration < ApplicationRecord
  belongs_to :project
  belongs_to :default_project, class_name: 'Project', optional: true

  has_many :external_issues, dependent: :destroy
  has_many :external_comments, dependent: :destroy

  # For PostgreSQL JSON columns use store_accessor (not store)
  # Native JSON columns don't need serialization - Rails handles it automatically
  store_accessor :settings, :statuses, :priorities

  after_initialize :set_default_settings, if: :new_record?

  validates :name,
            :key,
            :connector_id,
            :project_id,
            :statuses,
            :priorities, presence: true

  private

  def set_default_settings
    self.statuses ||= {}
    self.priorities ||= {}
  end
end
