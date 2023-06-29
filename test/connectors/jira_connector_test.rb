# TODO: it's only base, need to setup test environment
# require 'test/unit'
# require 'mocha/test_unit'

# class RedmineBridge::JiraConnectorTest < Test::Unit::TestCase
#   def setup
#     @logger = Rails.logger
#     @integration = BridgeIntegration.create!(
#       name: 'Jira',
#       connector_id: 'jira',
#       project_id: 1,
#       statuses: { '1' => '1' },
#       priorities: { '1' => '1' },
#       settings: {
#         jira_base_url: 'http://jira.example.com',
#         jira_username: 'jira_username',
#         jira_password: 'jira_password',
#         jira_project_id: 'PRJ'
#       }

#     )
#     @issue = Issue.create!(
#       project_id: 1,
#       name: 'Issue',
#     )
#     @external_issue = ExternalIssue.create!(
#       redmine_id: @issue.id,
#       external_id: 2,
#       external_url: 'http://jira.example.com/browse/PRJ-2',
#       connector_id: @integration.connector_id
#     )
#     @comment = issue.journals.create!(
#       notes: 'Comment'
#     )
#     @external_comment = ExternalComment.create!(
#       redmine_id: @comment.id,
#       external_id: 3,
#       external_url: 'http://jira.example.com/browse/PRJ-2?focusedCommentId=3',
#     )
#     @jira_issue = mock('JIRA::Client::Issue')
#     @jira_comment = mock('JIRA::Client::Comment')
#     JIRA::Client.any_instance.stubs(:Issue).returns(@jira_issue)
#     JIRA::Client.any_instance.stubs(:Comment).returns(@jira_comment)
#   end

#   def test_on_issue_create
#     @jira_issue.stubs(:save).returns(true)
#     @jira_issue.stubs(:id).returns(1)
#     jira_connector = RedmineBridge::JiraConnector.new(logger: @logger, integration: @integration)
#     jira_connector.on_issue_create(external_issue: @external_issue)
#     assert_equal @external_issue.reload.external_id, @jira_issue.id
#   end

#   def test_on_issue_update
#     @jira_issue.stubs(:save).returns(true)
#     jira_connector = RedmineBridge::JiraConnector.new(logger: @logger, integration: @integration)
#     jira_connector.on_issue_update(external_issue: @external_issue)
#     # Here, you may want to assert that the updated fields in Jira issue are indeed updated. Replace 'field' with actual field names
#     # assert_equal updated_field_value, @external_issue.reload.field
#   end

#   def test_on_comment_create
#     @jira_comment.stubs(:save).returns(true)
#     @jira_comment.stubs(:id).returns(1)
#     jira_connector = RedmineBridge::JiraConnector.new(logger: @logger, integration: @integration)
#     jira_connector.on_comment_create(external_comment: @external_comment)
#     assert_equal @external_comment.reload.external_id, @jira_comment.id
#   end

#   def test_on_comment_update
#     @jira_comment.stubs(:save).returns(true)
#     jira_connector = RedmineBridge::JiraConnector.new(logger: @logger, integration: @integration)
#     jira_connector.on_comment_update(external_comment: @external_comment)
#     # Here, you may want to assert that the updated fields in Jira comment are indeed updated. Replace 'field' with actual field names
#     # assert_equal updated_field_value, @external_comment.reload.field
#   end
# end
