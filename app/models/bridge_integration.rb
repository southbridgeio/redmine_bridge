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
end
