class RedmineBridge::CommentUpdateJob < ActiveJob::Base
  def perform(integration, external_comment, journal)
    RedmineBridge::Registry[integration.connector_id]
      .call(integration: integration)
      .on_comment_update(journal: journal,
                         external_comment: external_comment)
  end
end
