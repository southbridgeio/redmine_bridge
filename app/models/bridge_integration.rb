# frozen_string_literal: true

# Integration model
class BridgeIntegration < ActiveRecord::Base
  validates :name, :key, :connector_id, :project_id, presence: true
end
