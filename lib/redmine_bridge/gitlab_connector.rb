class RedmineBridge::GitlabConnector
  def on_issue_update(issue, integration)
    # TODO
  end

  def on_issue_create(issue)
    # TODO
  end

  def on_webhook_event(integration:, params:, issue_repository:)
    if params['event_type'] == 'issue'
      case params.dig('object_attributes', 'action')
      when 'open'
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: params.dig('object_attributes').values_at('id', 'project_id').join('-'),
          url: params.dig('object_attributes', 'url'),
          status_id: params.dig('object_attributes', 'state')
        )
        issue_repository.create(external_attributes,
                                project_id: integration.project_id,
                                subject: params.dig('object_attributes', 'title'),
                                description: params.dig('object_attributes', 'description'),
                                tracker: Tracker.first,
                                author: User.anonymous)
      when 'close'
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: params.dig('object_attributes').values_at('id', 'project_id').join('-'),
          status_id: params.dig('object_attributes', 'state')
        )
        issue_repository.update(external_attributes)
      when 'reopen'
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: params.dig('object_attributes').values_at('id', 'project_id').join('-'),
          status_id: params.dig('object_attributes', 'state')
        )
        issue_repository.update(external_attributes)
      when 'update'
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: params.dig('object_attributes').values_at('id', 'project_id').join('-'),
          status_id: params.dig('object_attributes', 'state')
        )
        issue_repository.update(external_attributes,
                                subject: params.dig('object_attributes', 'title'),
                                description: params.dig('object_attributes', 'description'))
      else
        raise 'Unknown action'
      end
    elsif params['event_type'] == 'note' && params['issue']
      issue_repository.add_notes(params.dig('issue').values_at('id', 'project_id').join('-'),
                                 "Автор: #{params.dig('user', 'name')}\n#{params.dig('object_attributes', 'note')}")
    end
  end
end
