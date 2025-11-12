# redmine_bridge

redmine_bridge provides ability to sync redmine issues with various platforms such as Gitlab, Jira, etc.

There're some built-in connectors provided with plugin, such as:

- Gitlab (two-way sync)
- Jira (Only Jira -> Redmine sync)

## Requirements

- Redmine 6.0 or higher (for Rails 7.2 support)
- Ruby 3.0 or higher
- PostgreSQL with JSON column support (recommended) or any database with TEXT columns

For legacy versions:
- Redmine 4.0-5.x with Ruby 2.5+ (use older plugin versions)

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

## Migration to Rails 7.x
**Note**: This migration only needs to be run once when upgrading from Rails < 7.2 to Rails 7.2+.

### Changes in Rails 7.2

Rails 7.2 introduced changes to ActiveRecord serialization that affect this plugin:

- **ActiveRecord `store` behavior changed**: No longer uses implicit YAML coder, requires explicit `coder:` parameter
- **PostgreSQL JSON column handling**: Native JSON columns now require `store_accessor` instead of `store` to avoid double serialization
- **Form helpers syntax**: `form_with` requires proper `fields_for` usage for nested attributes

This plugin was updated to use `store_accessor` for PostgreSQL JSON columns, which is the recommended Rails 7.2+ approach.

### Pre-migration Steps

Before upgrading to Rails 7.2+:

1. **Check your settings data** in the `bridge_integrations` table. If the `settings` field contains data in a format other than `JSON`, you need to migrate
2. **Backup your database** - especially the `bridge_integrations` table

### Migration Steps

After deploying Redmine code with the updated plugin:

1. **Run the data migration task**:
   ```bash
   cd {REDMINE_ROOT}
   RAILS_ENV=production bundle exec rake redmine_bridge:migrate_settings_to_json
   ```

2. **Verify the migration**:
   - Check migration output - should show: `"Migration completed"` and should't see any errors
   - Visit `/settings/plugin/redmine_bridge` and verify all integrations are visible
   - Edit an integration to confirm settings are preserved
   - Test creating a new integration

### Migration Task Details

The migration task (`redmine_bridge:migrate_settings_to_json`) will:
- Convert legacy YAML-serialized settings to clean JSON format
- Preserve all existing data (statuses, priorities, connector settings)
- Skip already-migrated records automatically
- Report any errors during migration

**Note**: This script may not account for all possible serialization duplications and other settings field format deviations that may have occurred during previous Rails updates. If for some reason you are unable to migrate your configs, you will need to either manually convert them to JSON format or delete all plugin configs and re-add them.

## License

[MIT](https://github.com/southbridgeio/redmine_bridge/blob/master/LICENSE)

## Author of the Plugin

The plugin is designed by [Southbridge](https://southbridge.io)
