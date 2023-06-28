class RedmineBridge::JiraConnector
  def initialize(logger: Rails.logger, integration:)
    @logger = logger
    @integration = integration
  end

  #######
  ### Redmine to Jira
  #######

  def on_issue_create(external_issue:)
    sync_operation(external_issue) do
      jira_issue = create_issue_in_jira(external_issue)
      external_url = integration.settings['jira_base_url'] + '/browse/' + jira_issue.key
      external_issue.update!(external_id: jira_issue.id, external_url: external_url)
    end
  end

  def on_issue_update(external_issue:, journal:)
    if journal.notes.present?
      external_comment = integration.external_comments.create!(redmine_id: journal.id, connector_id: integration.connector_id, external_issue: external_issue)
      begin
        on_comment_create(external_comment: external_comment, journal: journal)
      rescue StandardError => e
        Airbrake.notify(e)
        external_comment.fail!
      end
    end
    # could be projects, where you have the rights to comment, but don't have for edit issue
    sync_operation(external_issue) do
      update_issue_in_jira(external_issue)
    end
  end

  def on_comment_create(external_comment:, journal:)
    return external_comment.skip! if external_comment.redmine_journal.notes.blank?

    sync_operation(external_comment) do
      jira_comment = create_comment_in_jira(external_comment)
      external_issue = external_comment.external_issue
      external_url = external_issue.external_url + '?focusedCommentId=' + jira_comment.id.to_s
      external_comment.update!(external_id: jira_comment.id, external_url: external_url)
    end
  end

  def on_comment_update(external_comment:, journal:)
    return external_comment.skip! if external_comment.redmine_journal.notes.blank?

    sync_operation(external_comment) do
      update_comment_in_jira(external_comment)
    end
  end

  #######
  ### Jira to Redmine
  #######

  # TODO: ExtenrnalIssue should be synced
  def on_webhook_event(params:, issue_repository:)
    project = integration.project

    processed =
      case params['issue_event_type_name']
      when 'issue_updated', 'issue_generic'
        external_attributes = RedmineBridge::ExternalAttributes.new(
          id: params.dig('issue', 'id'),
          status_id: params.dig('issue', 'fields', 'status', 'id'),
          priority_id: params.dig('issue', 'fields', 'priority', 'id'),
        )

        issue_repository.update(external_attributes,
                                subject: params.dig('issue', 'fields', 'summary'),
                                description: "#{params.dig('issue', 'fields', 'description')}")
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
                                description: "#{params.dig('issue', 'fields', 'description')}",
                                tracker: Tracker.first,
                                author: User.anonymous)
      # Because from Jira Server params['webhookEvent'] is 'jira:issue_updated' here
      when 'issue_commented', 'issue_comment_edited'
        handle_comments_webhook(params, issue_repository)
      end

    return if processed

    processed =
      case params['webhookEvent']
      when 'comment_created', 'comment_updated'
        # 'comment_created' from Jira Server could come without 'issue' in params
        # And it sends 'issue_commented' simultaniously
        handle_comments_webhook(params, issue_repository)
      end

    unless processed
      logger.warn("Unknown event (#{params['issue_event_type_name']} or #{params['webhookEvent']})")
    end
  end

  private

  attr_reader :logger, :jira_client, :integration

  # TODO: need to move to general connector
  def sync_operation(external_entity)
    external_entity.sync!

    username = integration.settings['jira_username']
    password = integration.settings['jira_password']
    site = integration.settings['jira_base_url']
    if username.blank? || password.blank? || site.blank?
      logger.info "Integration #{integration.id} don't have enough credentials for Jira, skipping sync"
      external_entity.skip!
      return
    end

    yield
    external_entity.done_sync!
  rescue StandardError => e
    logger.error "Failed to sync #{external_entity.class.name} for ID #{external_entity.redmine_id}: #{e.message}, #{e.try(:response).try(:body)}"

    external_entity.sync_errors = e.try(:response).try(:body)
    external_entity.fail!
    raise e
  end

  def handle_comments_webhook(params, issue_repository)
    issue_id = params.dig('issue', 'id')
    comment_id = params.dig('comment', 'id')
    body = params.dig('comment', 'body')
    author = params.dig('comment', 'author', 'displayName')
    notes = "Автор: #{author}\n<pre>#{body}</pre>"

    issue_repository.add_or_update_comment(issue_id, comment_id, notes)
  end

  def create_issue_in_jira(external_issue)
    issue = external_issue.redmine_issue
    status_id = integration.statuses[issue.status_id.to_s]
    # priority_id = integration.priorities[issue.priority_id.to_s]

    jira_issue = jira_client.Issue.build
    # TODO проверить если status_id или priority_id nil
    jira_issue.save!(
      'fields' => {
        'project' => { 'key' => integration.settings['jira_project_key'] },
        'summary' => issue.subject,
        # 'priority' => { 'id' => priority_id }, # TODO: should exist in the project
        'description' => issue.description,
        'issuetype' => { 'id' => integration.settings['jira_issue_type_id'] }
      }
    )
    update_status_in_jira(jira_issue, status_id)
    jira_issue
  end

  def update_issue_in_jira(external_issue)
    issue = external_issue.redmine_issue
    jira_issue = jira_client.Issue.find(external_issue.external_id)
    status_id = integration.statuses[issue.status_id.to_s]
    # priority_id = integration.priorities[issue.priority_id.to_s]
    jira_issue.save!(
      'fields' => {
        # 'priority' => { 'id' => priority_id }, # TODO error "Field 'priority' cannot be
        # set. It is not on the appropriate screen, or unknow"
        'summary' => issue.subject,
        'description' => issue.description,
      }
    )
    update_status_in_jira(jira_issue, status_id)
    jira_issue
  end

  def create_comment_in_jira(external_comment)
    comment = external_comment.redmine_journal
    external_issue = external_comment.external_issue
    body = "#{comment_author_text(comment)}#{comment.notes}"
    issue = jira_client.Issue.find(external_issue.external_id)
    jira_comment = issue.comments.build
    jira_comment.save!(
      'body' => body,
    )
    jira_comment
  end

  def update_comment_in_jira(external_comment)
    comment = external_comment.redmine_journal
    body = "#{comment_author_text(comment)}#{comment.notes}"
    external_issue = external_comment.external_issue
    issue = jira_client.Issue.find(external_issue.external_id)
    jira_comment = jira_client.Comment.find(external_comment.external_id, issue: issue)
    jira_comment.save!(
      'body' => body,
    )
    jira_comment
  end

  def comment_author_text(comment)
    author = comment.user
    "Автор: #{author.firstname} #{author.lastname}\n" if author
  end

  def update_status_in_jira(jira_issue, status_id)
    # jira_issue.attrs['fields'] - to check that is issue is new or not. In new issues
    # jira_issue.status raises exception
    return if jira_issue.attrs['fields'] && jira_issue.status.id.to_s == status_id.to_s

    # We can't just set status_id in task creation - jira returns error.
    # more https://stackoverflow.com/questions/23262558/how-to-change-transitions-to-a-issue-in-ruby-using-jira-ruby-gem/23297391#23297391
    transitions = jira_client.Transition.all(issue: jira_issue)
    transition = transitions.find{ |t| t.to.id == status_id }
    new_tran = jira_issue.transitions.build
    new_tran.save!("transition" => {"id" => transition.id})
  rescue => e
    logger.error("Can't update status in jira: #{jira_issue.id} #{jira_issue.summary} #{status_id} #{e.message}")
  end

  def jira_client
    username = integration.settings['jira_username']
    password = integration.settings['jira_password']
    site = integration.settings['jira_base_url']
    @jira_client ||=
      JIRA::Client.new(
        username: username,
        password: password,
        site: site,
        context_path: '',
        auth_type: :basic,
        read_timeout: 120
      )
  end

  def connector_id
    integration.connector_id
  end
end
