class RedmineBridge::CommentCreateJob < ActiveJob::Base
  def perform(integration, external_comment, journal)
    RedmineBridge::Registry[integration.connector_id]
      .call(integration: integration)
      .on_comment_create(journal: journal,
                         external_comment: external_comment)
  end
end
