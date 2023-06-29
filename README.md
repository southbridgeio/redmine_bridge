# redmine_bridge

redmine_bridge provides ability to sync redmine issues with various platforms such as Gitlab, Jira, etc.

There're some built-in connectors provided with plugin, such as:

- Gitlab (two-way sync)
- Jira (Only Jira -> Redmine sync)

## Requirements

- Redmine 4.0 or higher
- Ruby 2.5 or higher

## Installation

```
cd {REDMINE_ROOT}
git clone https://github.com/southbridgeio/redmine_bridge.git plugins/redmine_bridge
bundle install RAILS_ENV=production
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

## Details of Jira integration

You need username and password for Jira Server(self hosted). You need username and API token for Jira Cloud(https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/).

You can find statuses, priorities and issue type from urls(your should be logged in):
http://JIRA_HOST/rest/api/2/status
http://JIRA_HOST/rest/api/2/priority
http://JIRA_HOST/rest/api/2/issuetype

## License

[MIT](https://github.com/southbridgeio/redmine_bridge/blob/master/LICENSE)

## Author of the Plugin

The plugin is designed by [Southbridge](https://southbridge.io)
