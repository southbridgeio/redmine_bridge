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

You can find statuses from page  like https://myorgname.atlassian.net/secure/admin/ViewStatuses.jspa
(1) Assuming you have Jira Admin rights, then you can access Jira Administration > Issues > Statuses. You can then hover the "Edit" option under the ACTION column to see each status's ID (The link should show up at the bottom left of your screen).)

## License

[MIT](https://github.com/southbridgeio/redmine_bridge/blob/master/LICENSE)

## Author of the Plugin

The plugin is designed by [Southbridge](https://southbridge.io)
