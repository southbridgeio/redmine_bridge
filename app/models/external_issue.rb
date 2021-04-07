class ExternalIssue < ActiveRecord::Base
  belongs_to :redmine_issue, foreign_key: 'redmine_id', class_name: 'Issue'
end
