class RedmineBridge::PrometheusConnector
  CLIENTS_HEXDIGEST_FIELDS = %w[alertname namespace resource resourcequota].freeze
  SOUTHBRIDGE_HEXDIGEST_FIELDS = %w[alertname namespace resource resourcequota redmine_project instance].freeze

  STATUS_OK = 'OK'.freeze
  STATUS_PROBLEM = 'PROBLEM'.freeze
  ALERT_STATUS_VALUES = {
    'resolved' => STATUS_OK,
    'Resolve' => STATUS_OK,
    'firing' => STATUS_PROBLEM,
    'Problem' => STATUS_PROBLEM
  }.freeze

  def initialize(logger: Rails.logger, integration:)
    @logger = logger
    @integration = integration
  end

  def valid_for?(params)
    params.keys.include?('alerts')
  end

  def runner
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

  def on_webhook_event(params:, issue_repository:, test:)
    grouped_alerts(params).each do |key_hash, objects|
      external_key = key_hash[:key]
      subject = key_hash[:subject]
      project_id = key_hash[:project_id]
      text = summary_text(objects)

      external_issue = ExternalIssue.find_by(external_id: external_key)
      external_issue.destroy! if external_issue&.redmine_issue&.closed? && !test

      if ExternalIssue.exists?(external_id: external_key, connector_id: 'prometheus')
        issue_repository.add_notes(external_key, text, test: test)
      elsif objects[STATUS_PROBLEM].any?
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: external_key,
          url: '',
          priority_id: objects[STATUS_PROBLEM].map{ |alert| alert.dig('labels', 'severity') }.uniq.first # TODO: Perpahs more logic needs here
        )

        issue_repository.create(external_attributes,
                                test: test,
                                project_id: project_id,
                                subject: subject,
                                description: text,
                                tracker: Tracker.first,
                                author: User.anonymous)
      end
    end
  rescue ActiveRecord::StaleObjectError => e
    logger.warn("Error: #{e}. Too much requests from Prometheus, rescheduling with params: #{params}")

    RedmineBridge::WebhookJob.set(wait: 3.seconds).perform_later(integration, params)
  rescue ActiveRecord::RecordNotUnique => e
    # do nothing
  end

  private

  attr_reader :logger, :integration

  def grouped_alerts(params)
    Array.wrap(params['alerts']).each_with_object({}) do |alert, data|
      alert = alert.merge(params.slice('externalURL'))

      project = find_project(integration, alert)
      status = alert_status(alert)
      external_key = find_external_key(alert, integration)
      subject = alert_subject(alert, params['commonLabels'])
      key = { key: external_key, subject: subject, project_id: project&.id }

      data[key] ||= Hash.new { |h, k| h[k] = [] }
      data[key][status] << alert
    end
  end

  def alert_status(alert)
    alert_value = if alert.dig('labels', 'alertname') == 'Watchdog'
                    alert['status'] == 'resolved' ? 'firing' : 'resolved'
                  else
                    alert['status']
                  end
    ALERT_STATUS_VALUES[alert_value]
  end

  def alert_subject(alert, c_labels = {})
    alert_title = alert.dig('annotations', 'summary').presence || alert.dig('labels', 'alertname')
    stage = c_labels['cluster'].present? ? "#{c_labels['cluster']}:" : nil
    [stage, alert_title].compact.join(' ').truncate(255)
  end

  def summary_text(objects)
    objects.map do |status, alert|
      "**#{status}**\n\n" + alert.map { |alert| format_payload(alert) }.join("-" * 20 + "\n")
    end.join("\n\n")
  end

  def format_payload(payload, comment_block: false)
    locals = {
      start_time: payload['startsAt'],
      annotations: payload['annotations'],
      links: %w[grafana prometheus alertmanager kibana runbook_url kb graylog],
      external_url: payload['annotations']['alertmanager'] || payload['externalURL'],
      comment_block: comment_block
    }
    raise ArgumentError if locals.values.all?(&:blank?)

    ApplicationController.render('redmine_bridge/prometheus/description', layout: false, locals: locals)
  rescue StandardError => e
    Airbrake.notify(e) if defined?(Airbrake) && Rails.env.production?
    "<pre>#{JSON.pretty_generate(payload)}</pre>"
  end

  def find_project(integration, alert)
    integration.southbridge_integration? ? southbridge_project(integration, alert) : integration.project
  end

  def southbridge_project(integration, alert)
    default_project = integration.default_project
    main_project = integration.project
    redmine_project = alert.dig('labels', 'redmine_project')
    target_project = Project.find_by(identifier: redmine_project)

    all_parents(target_project).include?(main_project) ? target_project : default_project || main_project
  end

  def all_parents(target_project)
    return [] unless target_project&.parent

    [target_project, target_project.parent] + all_parents(target_project.parent)
  end

  def find_external_key(alert, integration)
    hexdigest_keys = integration.southbridge_integration? ? SOUTHBRIDGE_HEXDIGEST_FIELDS : CLIENTS_HEXDIGEST_FIELDS

    Digest::MD5.hexdigest("#{alert['labels'].values_at(*hexdigest_keys).join}#{alert['externalURL']}")
  end
end
