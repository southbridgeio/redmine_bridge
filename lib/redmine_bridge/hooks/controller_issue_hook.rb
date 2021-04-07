module RedmineBridge
  module Hooks
    class ControllerIssueHook < Redmine::Hook::ViewListener
      include AfterCommitEverywhere

      def controller_issues_edit_after_save(issue:, journal:, **)
        bridge_integration = BridgeIntegration.find_by(project_id: issue.project_id)
        return unless bridge_integration

        external_issue = ExternalIssue.find_by(redmine_id: issue.id, connector_id: bridge_integration.connector_id)
        return unless external_issue

        after_commit { RedmineBridge::IssueUpdateJob.perform_later(bridge_integration, external_issue, journal) }
      end
    end
  end
end
