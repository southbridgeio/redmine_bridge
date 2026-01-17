namespace :redmine_bridge do
  desc 'Migrate settings from YAML to JSON format (Rails 7.2 compatibility)'
  task migrate_settings_to_json: :environment do
    puts "=" * 80
    puts "Migrating BridgeIntegration settings: YAML → JSON"
    puts "=" * 80
    puts ""

    success_count = 0
    error_count = 0
    skipped_count = 0

    BridgeIntegration.find_each do |integration|
      begin
        raw_settings = integration.read_attribute_before_type_cast(:settings)

        if raw_settings.start_with?('{') || raw_settings.start_with?('[')
          puts "Integration ##{integration.id} (#{integration.name}): already in JSON format"
          skipped_count += 1
          next
        end

        settings_hash = YAML.load(integration.settings, permitted_classes: [ActiveSupport::HashWithIndifferentAccess])
        integration.update(settings: settings_hash)

        puts "Integration ##{integration.id} (#{integration.name}): migrated"
        success_count += 1
      rescue => e
        puts "Integration ##{integration.id} (#{integration.name}): ERROR - #{e.message}"
        error_count += 1
      end
    end

    puts "=" * 80
    puts "Migration completed"
    puts "=" * 80
    puts "Migrated: #{success_count}"
    puts "Skipped: #{skipped_count}"
    puts "Errors: #{error_count}"
  end
end
