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

## License

[MIT](https://github.com/southbridgeio/redmine_bridge/blob/master/LICENSE)

## Author of the Plugin

The plugin is designed by [Southbridge](https://southbridge.io)

