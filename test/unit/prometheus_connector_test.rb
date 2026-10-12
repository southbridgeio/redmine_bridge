require File.expand_path('../../test_helper', __FILE__)

class RedmineBridge::PrometheusConnectorTest < ActiveSupport::TestCase
  fixtures :projects, :users, :trackers, :issue_statuses, :enumerations, :issues

  EXTERNAL_KEY = 'prometheus-alert-key'.freeze

  def setup
    @issue = Issue.find(1)
    ExternalIssue.create!(redmine_id: @issue.id, external_id: EXTERNAL_KEY, connector_id: 'prometheus')

    integration = stub(southbridge_integration?: false, project: @issue.project)
    @connector = RedmineBridge::PrometheusConnector.new(integration: integration)
    @connector.stubs(:find_external_key).returns(EXTERNAL_KEY)

    @issue_repository = mock('issue_repository')
    @issue_repository.stubs(:add_notes)
  end

  def test_repeated_alert_does_not_update_priority_of_issue_in_work
    IssueStatus.stubs(:working_ids).returns([@issue.status_id])

    @issue_repository.expects(:update).never

    @connector.on_webhook_event(params: alert_params, issue_repository: @issue_repository, test: false)
  end

  def test_repeated_alert_updates_priority_of_issue_not_in_work
    IssueStatus.stubs(:working_ids).returns([])

    @issue_repository.expects(:update).with do |attributes|
      attributes.id == EXTERNAL_KEY && attributes.priority_id == 'critical'
    end

    @connector.on_webhook_event(params: alert_params, issue_repository: @issue_repository, test: false)
  end

  private

  def alert_params
    {
      'commonLabels' => {},
      'alerts' => [{
        'status' => 'firing',
        'labels' => { 'alertname' => 'ExternalServiceDown', 'severity' => 'critical' },
        'annotations' => { 'summary' => 'External service is down' },
        'startsAt' => '2026-10-10T10:00:00Z'
      }]
    }
  end
end
