class RedmineBridge::PrometheusConnector
  def on_issue_update(*)
    # TODO
  end

  def on_issue_create(*)
    # TODO
  end

  def on_webhook_event(integration:, params:, issue_repository:)
    project = integration.project
    common_labels = params['commonLabels'] || {}

    Array.wrap(params['alerts']).each do |alert|
      alert = alert.merge(params.slice('externalURL'))
      external_key = Digest::MD5.hexdigest("#{alert['labels'].values_at('alertname', 'namespace', 'resource', 'resourcequota').join}#{alert['externalURL']}")

      external_issue = ExternalIssue.find_by(external_id: external_key)
      external_issue.destroy! if external_issue&.redmine_issue&.closed?

      alert_name = alert.dig('labels', 'alertname')
      alert_status = if alert_name == 'Watchdog'
                       alert['status'] == 'resolved' ? 'firing' : 'resolved'
                     else
                       alert['status']
                     end

      if ExternalIssue.exists?(external_id: external_key, connector_id: 'prometheus')
        case alert_status
        when 'resolved', 'Resolve'
          issue_repository.add_notes(external_key, "Инцидент завершён:\n#{format_payload(alert)}")
        when 'firing', 'Problem'
          issue_repository.add_notes(external_key, "Новое состояние:\n#{format_payload(alert)}")
        end
      elsif alert_status != 'resolved'
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: external_key,
          url: '',
          priority_id: alert.dig('labels', 'severity')
        )

        alert_title = alert.dig('annotations', 'summary').presence || alert.dig('labels', 'alertname')
        stage = common_labels['cluster'].present? ? "#{common_labels['cluster']}:" : nil
        subject = [stage, alert_title].compact.join(' ')

        issue_repository.create(external_attributes,
                                project_id: project.id,
                                subject: subject,
                                description: format_payload(alert),
                                tracker: Tracker.first,
                                author: User.anonymous)
      end
    end
  end

  private

  def format_payload(payload)
    locals = {
      start_time: payload['startsAt'],
      annotations: payload['annotations'],
      links: %w[grafana prometheus alertmanager kibana runbook_url],
      external_url: payload['annotations']['alertmanager'] || payload['externalURL']
    }
    raise ArgumentError if locals.values.all?(&:blank?)

    ApplicationController.render('redmine_bridge/prometheus/description', layout: false, locals: locals)
  rescue StandardError => e
    Airbrake.notify(e) if defined?(Airbrake) && Rails.env.production?
    "<pre>#{JSON.pretty_generate(payload)}</pre>"
  end
end
