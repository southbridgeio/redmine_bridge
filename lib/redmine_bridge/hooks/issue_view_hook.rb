module RedmineBridge
  module Hooks
    class IssueViewHook < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom, partial: 'redmine_bridge/issues/bottom'
    end
  end
end
