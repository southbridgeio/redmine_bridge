class RedmineBridge::JiraConnector
  def on_issue_update(issue, integration)
    # TODO
  end

  def on_issue_create(issue)
    # TODO
  end

  def on_webhook_event(integration:, request:, issue_repository:)
    project = integration.project
    params = request.params

    case params['issue_event_type_name']
    when 'issue_updated'
      issue_repository.update(params.dig('issue', 'id'),
                              subject: params.dig('issue', 'fields', 'summary'),
                              description: params.dig('issue', 'fields', 'description'))
    when 'issue_created'
      issue_repository.create(params.dig('issue', 'id'),
                              "http://localhost:8080/browse/#{params.dig('issue', 'key')}",
                              project_id: project.id,
                              subject: params.dig('issue', 'fields', 'summary'),
                              description: params.dig('issue', 'fields', 'description'),
                              tracker: Tracker.first,
                              author: User.anonymous)
    when 'issue_commented'
      issue_repository.add_notes(params.dig('issue', 'id'),
                                 params.dig('issue', 'fields', 'comment', 'comments').last['body'])
    else
      # skip
    end
  end
end
