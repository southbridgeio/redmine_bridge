require_relative 'lib/omni_markup'
require_relative 'lib/omni_markup/redmine_textile'
require_relative 'lib/omni_markup/gitlab_markdown'

reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader
reloader.to_prepare do
  paths = '/lib/redmine_bridge/{patches/*_patch,hooks/*_hook}.rb'
  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end
end

Rails.application.config.eager_load_paths += Dir.glob("#{Rails.application.config.root}/plugins/redmine_bridge/{lib,app/models,app/controllers}")

Redmine::Plugin.register :redmine_bridge do
  name 'Redmine Bridge'
  author 'Slurm'
  description 'This is a plugin for Redmine'
  version '1.0.1'
  url 'https://github.com/southbridgeio/redmine_bridge'
  author_url 'https://slurm.io'

  settings default: { 'empty' => true }, partial: 'bridge_integrations/index'
end
