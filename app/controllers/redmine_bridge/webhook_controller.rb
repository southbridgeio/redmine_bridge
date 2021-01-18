class RedmineBridge::WebhookController < ActionController::Base
  # POST /redmine_bridge/webhook
  def index
    # Предполагается, что мы по params[:key] ищем интеграцию проекта с трекером и по ней определяем коннектор и проект
    connector.on_webhook_event(request: request,
                               project: project,
                               create_issue: ->(params) { Issue.create(params) },
                               update_issue: ->(issue, params) { issue.update(params) }
    )
  end

  private

  def project
    @project ||= Project.first
  end

  def connector
    RedmineBridge::JiraConnector.new
  end
end
