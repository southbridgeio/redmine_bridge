class RedmineBridge::PrometheusConnector
  HEXDIGEST_FIELDS = %w[alertname namespace resource resourcequota redmine_project].freeze

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

  def on_webhook_event(params:, issue_repository:)
    project = find_project(integration, params)
    common_labels = params['commonLabels'] || {}

    Array.wrap(params['alerts']).each do |alert|
      alert = alert.merge(params.slice('externalURL'))
      # TODO: это надо проверить, что нет пересечений(что какие-то уникальные параметры
      # есть, время там или т.п.)
      external_key = Digest::MD5.hexdigest("#{alert['labels'].values_at(*HEXDIGEST_FIELDS).join}#{alert['externalURL']}")

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

  attr_reader :logger, :integration

  def format_payload(payload)
    locals = {
      start_time: payload['startsAt'],
      annotations: payload['annotations'],
      links: %w[grafana prometheus alertmanager kibana runbook_url kb graylog],
      external_url: payload['annotations']['alertmanager'] || payload['externalURL']
    }
    raise ArgumentError if locals.values.all?(&:blank?)

    ApplicationController.render('redmine_bridge/prometheus/description', layout: false, locals: locals)
  rescue StandardError => e
    Airbrake.notify(e) if defined?(Airbrake) && Rails.env.production?
    "<pre>#{JSON.pretty_generate(payload)}</pre>"
  end

  def find_project(integration, params)
    southbridge_project?(params) ? southbridge_project(integration, params) : integration.project
  end

  def southbridge_project(integration, params)
    default_project = integration.default_project
    main_project = integration.project
    target_project = Project.find_by(identifier: redmine_project(params))

    all_parents(target_project).include?(main_project) ? target_project : default_project || main_project
  end

  def all_parents(target_project)
    return [] unless target_project&.parent
    [target_project, target_project.parent] + all_parents(target_project.parent)
  end

  def southbridge_project?(params)
    redmine_project(params).present?
  end

  def redmine_project(params)
    @redmine_project ||= params.dig('alerts', 0, 'labels', 'redmine_project')
  end
end
