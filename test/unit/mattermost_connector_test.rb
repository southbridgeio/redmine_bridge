require File.expand_path('../../test_helper', __FILE__)

class RedmineBridge::MattermostConnectorTest < ActiveSupport::TestCase
  def test_private_notes_are_not_sent_to_mattermost
    connector = RedmineBridge::MattermostConnector.new(integration: stub(settings: {}))
    journal = stub(private_notes?: true)
    external_issue = stub(external_id: 'root|post')

    RedmineBridge::MattermostClient.any_instance.expects(:issue_updated).never

    connector.on_issue_update(journal: journal, external_issue: external_issue)
  end
end
