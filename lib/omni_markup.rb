class OmniMarkup
  def self.from_gitlab_markdown(text)
    new(Nokogiri::HTML.fragment(CommonMarker.render_html(text).gsub("<br />\n", "<br />")))
  end

  def self.from_redmine_textile(text)
    new(Nokogiri::HTML.fragment(Redmine::WikiFormatting::Textile::Formatter.new(text).to_html.gsub("\t", '')))
  end

  def initialize(fragment)
    @fragment = fragment
  end

  def to_gitlab_markdown
    GitlabMarkdown.new(fragment).generate
  end

  def to_redmine_textile
    RedmineTextile.new(fragment).generate
  end

  private

  attr_reader :fragment
end
