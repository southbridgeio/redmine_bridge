class RedmineBridge::PrometheusConnector
  def initialize(logger: Rails.logger, integration:)
    @logger = logger
    @integration = integration
  end

  def on_issue_update(*)
    # TODO
  end

  def on_issue_create(*)
    # TODO
  end

  def on_comment_create(*)
    # TODO
  end

  def on_comment_update(*)
    # TODO
  end

  def check_connection
    raise NotImplementedError
  end

  def on_webhook_event(params:, issue_repository:)
    project = integration.project

    params['alerts'].each do |alert|
      alert = alert.merge(params.slice('externalURL'))
      # TODO: это надо проверить, что нет пересечений(что какие-то уникальные параметры
      # есть, время там или т.п.)
      external_key = Digest::MD5.hexdigest("#{alert['labels'].values_at('alertname', 'namespace', 'resource', 'resourcequota').join}#{alert['externalURL']}")

      external_issue = ExternalIssue.find_by(external_id: external_key)
      external_issue.destroy! if external_issue&.redmine_issue&.closed?

      if ExternalIssue.exists?(external_id: external_key, connector_id: 'prometheus')
        case alert['status']
        when 'resolved', 'Resolve'
          issue_repository.add_notes(external_key, "**OK**\n#{format_payload(alert, comment_block: true)}")
        when 'firing', 'Problem'
          issue_repository.add_notes(external_key, "**PROBLEM**\n#{format_payload(alert, comment_block: true)}")
        end
      elsif alert['status'] != 'resolved'
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: external_key,
          url: '',
          priority_id: alert.dig('labels', 'severity')
        )

        title = alert.dig('annotations', 'summary').presence || alert.dig('labels', 'alertname')
        issue_repository.create(external_attributes,
                                project_id: project.id,
                                subject: "Prometheus: #{title}",
                                description: format_payload(alert),
                                tracker: Tracker.first,
                                author: User.anonymous)
      end
    end
  end

  private

  attr_reader :logger, :integration

  def format_payload(payload, comment_block: false)
    locals = {
      start_time: payload['startsAt'],
      annotations: payload['annotations'],
      links: %w[grafana prometheus alertmanager kibana runbook_url],
      external_url: payload['annotations']['alertmanager'] || payload['externalURL'],
      comment_block: comment_block
    }
    raise ArgumentError if locals.values.all?(&:blank?)

    ApplicationController.render('redmine_bridge/prometheus/description', layout: false, locals: locals)
  rescue StandardError => e
    Airbrake.notify(e) if defined?(Airbrake) && Rails.env.production?
    "<pre>#{JSON.pretty_generate(payload)}</pre>"
  end
end
