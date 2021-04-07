class RedmineBridge::JiraConnector
  def on_issue_update(issue, integration)
    # TODO
  end

  def on_issue_create(issue)
    # TODO
  end

  def on_webhook_event(integration:, params:, issue_repository:)
    project = integration.project

    case params['issue_event_type_name']
    when 'issue_updated', 'issue_generic'
      external_attributes = RedmineBridge::ExternalAttributes.new(
        id: params.dig('issue', 'id'),
        status_id: params.dig('issue', 'fields', 'status', 'id'),
        priority_id: params.dig('issue', 'fields', 'priority', 'id'),
      )

      issue_repository.update(external_attributes,
                              subject: params.dig('issue', 'fields', 'summary'),
                              description: "<pre>#{params.dig('issue', 'fields', 'description')}</pre>")
    when 'issue_created'
      uri = URI(params.dig('issue', 'self'))

      base_url = "#{uri.scheme}://#{uri.host}#{uri.port == 80 ? '' : ":#{uri.port}"}"

      external_attributes = RedmineBridge::ExternalAttributes.new(
        id: params.dig('issue', 'id'),
        status_id: params.dig('issue', 'fields', 'status', 'id'),
        priority_id: params.dig('issue', 'fields', 'priority', 'id'),
        url: File.join(base_url, "browse/#{params.dig('issue', 'key')}")
      )
      issue_repository.create(external_attributes,
                              project_id: project.id,
                              subject: params.dig('issue', 'fields', 'summary'),
                              description: "<pre>#{params.dig('issue', 'fields', 'description')}</pre>",
                              tracker: Tracker.first,
                              author: User.anonymous)
    when 'issue_commented'
      issue_repository.add_notes(params.dig('issue', 'id'),
                                 "Автор: #{params.dig('user', 'displayName')}\n<pre>#{params.dig('issue', 'fields', 'comment', 'comments').last['body']}</pre>")
    else
      raise "Unknown event (#{params['issue_event_type_name']})"
    end
  end
end
