module RedmineBridge
  module Hooks
    class ControllerIssueHook < Redmine::Hook::ViewListener
      include AfterCommitEverywhere

      # after issue creation
      def controller_issues_new_after_save(issue:, **)
        bridge_integration = BridgeIntegration.find_by(project_id: issue.project_id)
        return unless bridge_integration

        external_issue = ExternalIssue.find_by(redmine_id: issue.id, connector_id: bridge_integration.connector_id)
        if external_issue
          Rails.logger.info "Issue with id #{issue.id} already exist in external system. bridge_integration_id: #{bridge_integration.id}"
        else
          external_issue = bridge_integration.external_issues.create!(redmine_id: issue.id, connector_id: bridge_integration.connector_id)
          after_commit { RedmineBridge::IssueCreateJob.perform_later(bridge_integration, external_issue) }
        end
      end

      # after issue updation(comments also here)
      def controller_issues_edit_after_save(issue:, journal:, **)
        bridge_integration = BridgeIntegration.find_by(project_id: issue.project_id)
        return unless bridge_integration

        # could be nil if we change some old issue(which exist in our project,
        # but does not exist in external)
        external_issue = ExternalIssue.find_by(redmine_id: issue.id, connector_id: bridge_integration.connector_id)
        return unless external_issue

        # TODO: temporal for migration period before old data will be updated.
        external_issue.bridge_integration = bridge_integration
        external_issue.save!
        after_commit { RedmineBridge::IssueUpdateJob.perform_later(bridge_integration, external_issue, journal) }
      end

      # here only comments editing(not creation)
      def controller_journals_edit_post(journal:, **)
        issue = journal.issue
        bridge_integration = BridgeIntegration.find_by(project_id: issue.project_id)
        return unless bridge_integration

        external_comment = bridge_integration.external_comments.find_by(redmine_id: journal.id, connector_id: bridge_integration.connector_id)
        if external_comment
          after_commit { RedmineBridge::CommentUpdateJob.perform_later(bridge_integration, external_comment, journal) }
        else
          external_issue = ExternalIssue.find_by(redmine_id: issue.id, connector_id: bridge_integration.connector_id)
          unless external_issue
            Rails.logger.error "External issue is not found for redmine_id: #{issue.id}, integration_id: #{bridge_integration.id}, journal_id: #{journal.id}"
            return
          end
          external_comment = bridge_integration.external_comments.create!(redmine_id: journal.id, connector_id: bridge_integration.connector_id, external_issue: external_issue)
          after_commit { RedmineBridge::CommentCreateJob.perform_later(bridge_integration, external_comment, journal) }
        end
      end
    end
  end
end
