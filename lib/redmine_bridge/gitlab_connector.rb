class RedmineBridge::GitlabConnector
  module IntegrationRefinements
    refine BridgeIntegration do
      def gitlab_client
        @gitlab_client ||= RedmineBridge::GitlabClient.new(base_url: settings['base_url'],
                                                          access_token: settings['access_token'])
      end

      def update_gitlab_issue(*args)
        return if settings.values_at('base_url', 'access_token').any?(&:blank?)

        gitlab_client.update_issue(*args)
      end

      def create_discussion(*args)
        return if settings.values_at('base_url', 'access_token').any?(&:blank?)

        gitlab_client.create_discussion(*args)
      end
    end
  end

  using IntegrationRefinements

  def initialize(logger:)
    @logger = logger
  end

  def on_issue_update(journal:, external_issue:, integration:)
    issue_iid, project_id = external_issue.external_id.split('-')

    if journal.notes.present?
      integration.create_discussion(project_id, issue_iid,
                                    body: "Автор: #{journal.user.name}  \n#{convert_to_markdown(journal.notes)}")
    end

    gitlab_params = journal.details.reduce({}) do |result, detail|
      property =
        case detail.prop_key
        when 'description'
          { description: convert_to_markdown(detail.value) }
        when 'subject'
          { title: detail.value }
        when 'status_id'
          case integration.statuses[detail.value]
          when 'opened'
            { state_event: 'reopen' }
          when 'closed'
            { state_event: 'close'}
          else
            {}
          end
        else
          {}
        end
      result.merge(property)
    end

    return if gitlab_params.blank?

    integration.update_gitlab_issue(project_id, issue_iid, gitlab_params)
  end

  def on_issue_create(issue)
    # TODO
  end

  def on_webhook_event(integration:, params:, issue_repository:)
    # TODO
    return if params.dig('user', 'email')&.include?('@example.com')

    if params['event_type'] == 'issue'
      case params.dig('object_attributes', 'action')
      when 'open'
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: params.dig('object_attributes').values_at('iid', 'project_id').join('-'),
          url: params.dig('object_attributes', 'url'),
          status_id: params.dig('object_attributes', 'state')
        )
        issue_repository.create(external_attributes,
                                project_id: integration.project_id,
                                subject: params.dig('object_attributes', 'title'),
                                description: convert_to_textile(params.dig('object_attributes', 'description')),
                                tracker: Tracker.first,
                                author: User.anonymous)
      when 'close'
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: params['object_attributes'].values_at('iid', 'project_id').join('-'),
          status_id: params.dig('object_attributes', 'state')
        )
        issue_repository.update(external_attributes)
      when 'reopen'
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: params.dig('object_attributes').values_at('iid', 'project_id').join('-'),
          status_id: params.dig('object_attributes', 'state')
        )
        issue_repository.update(external_attributes)
      when 'update'
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: params['object_attributes'].values_at('iid', 'project_id').join('-'),
          status_id: params.dig('changes', 'state_id') ? params.dig('object_attributes', 'state') : nil
        )
        issue_repository.update(external_attributes,
                                subject: params.dig('object_attributes', 'title'),
                                description: convert_to_textile(params.dig('object_attributes', 'description')))

        if params.dig('changes', 'assignees', 'current')
          names = params.dig('changes', 'assignees', 'current').map { |u| u['name'] }
          issue_repository.add_notes(params['object_attributes'].values_at('iid', 'project_id').join('-'),
                                     "Задача назначена на #{names.join(', ')}")
        end
      else
        logger.warn('Unknown action')
      end
    elsif params['event_type'] == 'note' && params['issue']
      issue_repository.add_notes(params['issue'].values_at('iid', 'project_id').join('-'),
                                 "Автор: #{params.dig('user', 'name')}\n#{convert_to_textile(params.dig('object_attributes', 'note'))}")
    end
  end

  private

  attr_reader :logger

  def convert_to_textile(text)
    OmniMarkup.from_gitlab_markdown(text).to_redmine_textile
  end

  def convert_to_markdown(text)
    OmniMarkup.from_redmine_textile(text).to_gitlab_markdown
  end
end
