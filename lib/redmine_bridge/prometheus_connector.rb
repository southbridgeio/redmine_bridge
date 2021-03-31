class RedmineBridge::PrometheusConnector
  def on_issue_update(issue, integration)
    # TODO
  end

  def on_issue_create(issue)
    # TODO
  end

  def on_webhook_event(integration:, params:, issue_repository:)
    project = integration.project

    external_issue = ExternalIssue.find_by(external_id: params['groupKey'])
    external_issue.destroy! if external_issue&.redmine_issue&.closed?

    if ExternalIssue.exists?(external_id: params['groupKey'], connector_id: 'prometheus')
      case params['status']
      when 'resolved', 'Resolve'
        issue_repository.add_notes(params['groupKey'], "Инцидент завершён:\n#{format_payload(params)}")
      when 'firing', 'Problem'
        issue_repository.add_notes(params['groupKey'], "Новое состояние:\n#{format_payload(params)}")
      end
    elsif params['status'] != 'resolved'
      external_attributes = RedmineBridge::ExternalAttributes.new(
        id: params['groupKey'],
        url: '',
        priority_id: params['alerts'].first.dig('labels', 'severity')
      )
      issue_repository.create(external_attributes,
                              project_id: project.id,
                              subject: "Prometheus: #{params.dig('commonAnnotations', 'summary')}",
                              description: format_payload(params),
                              tracker: Tracker.first,
                              author: User.anonymous)
    end
  end

  private

  def format_payload(payload)
    locals = {
      description: payload.dig('commonAnnotations', 'summary'),
      start_time: payload['alerts'].first['startsAt'],
      dashboard_url: payload.dig('commonAnnotations', 'dashboard'),
      kb_url: payload.dig('commonAnnotations', 'kb')
    }
    raise ArgumentError if locals.values.all?(&:blank?)

    ApplicationController.render('redmine_bridge/prometheus/description', layout: false, locals: locals)
  rescue StandardError => e
    Airbrake.notify(e) if Rails.env.production?
    "<pre>#{JSON.pretty_generate(payload)}</pre>"
  end
end
