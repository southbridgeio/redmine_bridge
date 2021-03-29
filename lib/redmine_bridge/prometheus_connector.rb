class RedmineBridge::PrometheusConnector
  def on_issue_update(issue, integration)
    # TODO
  end

  def on_issue_create(issue)
    # TODO
  end

  def on_webhook_event(integration:, params:, issue_repository:)
    project = integration.project

    if external_issue = ExternalIssue.find_by(external_id: params['groupKey'])
      case params['status']
      when 'resolved', 'Resolve'
        issue_repository.add_notes(params['groupKey'], "Инцидент завершён:\n#{format_payload(params)}")
      when 'firing', 'Problem'
        ActiveRecord::Base.transaction do
          external_attributes = RedmineBridge::ExternalAttributes.new(
            id: params['groupKey'],
            url: params['externalURL'],
            priority_id: params.dig('alerts', 'labels', 'severity')
          )
          issue_repository.update(external_attributes, status: IssueStatus.sorted.first) if external_issue.redmine_issue&.closed?
          issue_repository.add_notes(params['groupKey'], "Новое состояние:\n#{format_payload(params)}")
        end
      end
    elsif params['status'] != 'resolved'
      external_attributes = RedmineBridge::ExternalAttributes.new(
        id: params['groupKey'],
        url: params['externalURL'],
        priority_id: params['severity']
      )
      issue_repository.create(external_attributes,
                              project_id: project.id,
                              subject: params['alerts'].first.dig('labels', 'alertname'),
                              description: format_payload(params),
                              tracker: Tracker.first,
                              author: User.anonymous)
    end
  end

  private

  def format_payload(payload)
    [
      "#{payload.dig('commonAnnotations', 'summary')}\nВремя начала: #{payload['alerts'].first['startsAt']}",
      payload.dig('commonAnnotations', 'dashboard', 'value'),
      payload.dig('commonAnnotations', 'kb')
    ].reject(&:blank?).join("\n")
  end
end
