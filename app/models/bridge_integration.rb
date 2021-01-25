# frozen_string_literal: true

# Integration model
class BridgeIntegration < ActiveRecord::Base
  belongs_to :project

  store :settings, accessors: %i[statuses priorities]

  validates :name,
            :key,
            :connector_id,
            :project_id,
            :statuses,
            :priorities, presence: true
end
