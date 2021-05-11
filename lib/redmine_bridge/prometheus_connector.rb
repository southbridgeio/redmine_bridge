class RedmineBridge::PrometheusConnector
  def on_issue_update(issue, integration)
    # TODO
  end

  def on_issue_create(issue)
    # TODO
  end

  def on_webhook_event(integration:, params:, issue_repository:)
    project = integration.project

    external_key = "#{params['groupKey']}.#{params.dig('commonLabels', 'alertname')}"

    external_issue = ExternalIssue.find_by(external_id: external_key)
    external_issue.destroy! if external_issue&.redmine_issue&.closed?

    if ExternalIssue.exists?(external_id: external_key, connector_id: 'prometheus')
      case params['status']
      when 'resolved', 'Resolve'
        issue_repository.add_notes(external_key, "Инцидент завершён:\n#{format_payload(params)}")
      when 'firing', 'Problem'
        issue_repository.add_notes(external_key, "Новое состояние:\n#{format_payload(params)}")
      end
    elsif params['status'] != 'resolved'
      external_attributes = RedmineBridge::ExternalAttributes.new(
        id: external_key,
        url: '',
        priority_id: params['alerts'].first.dig('labels', 'severity')
      )

      title = params.dig('commonAnnotations', 'summary').presence || params.dig('commonLabels', 'alertname')
      issue_repository.create(external_attributes,
                              project_id: project.id,
                              subject: "Prometheus: #{title}",
                              description: format_payload(params),
                              tracker: Tracker.first,
                              author: User.anonymous)
    end
  end

  private

  def format_payload(payload)
    locals = {
      start_time: payload['alerts'].first['startsAt'],
      common_annotations: payload['commonAnnotations'],
      external_url: payload['externalURL']
    }
    raise ArgumentError if locals.values.all?(&:blank?)

    ApplicationController.render('redmine_bridge/prometheus/description', layout: false, locals: locals)
  rescue StandardError => e
    Airbrake.notify(e) if Rails.env.production?
    "<pre>#{JSON.pretty_generate(payload)}</pre>"
  end
end
