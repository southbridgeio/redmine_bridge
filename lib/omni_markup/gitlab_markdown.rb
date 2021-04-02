class OmniMarkup::GitlabMarkdown
  def initialize(fragment)
    @fragment = fragment
  end

  def generate(fragment = self.fragment, result = '')
    addition =
      case fragment.name
      when '#document-fragment'
        generate_children(fragment)
      when 'text'
        fragment.text
      when 'br'
        "  \n"
      when 'b', 'strong'
        "**#{generate_children(fragment)}**"
      when 'i', 'em'
        "_#{generate_children(fragment)}_"
      when 'strike'
        "~~#{generate_children(fragment)}~~"
      when 'h1'
        "# #{generate_children(fragment)}"
      when 'h2'
        "## #{generate_children(fragment)}"
      when 'h3'
        "### #{generate_children(fragment)}"
      when 'code'
        "```#{"#{fragment[:class].sub(' syntaxhl', '')}" if fragment[:class]}\n#{fragment.text}```"
      when 'ol', 'ul'
        generate_children(fragment)
      when 'li'
        if fragment.parent.name == 'ul'
          "- #{generate_children(fragment)}"
        elsif fragment.parent.name == 'ol'
          "1. #{generate_children(fragment)}"
        else
          ''
        end
      when 'a'
        "[#{fragment.text}](#{fragment[:href]})"
      when 'blockquote'
        "> #{fragment.text}"
      else
        generate_children(fragment)
      end
    result + addition
  end

  protected

  attr_reader :fragment

  def generate_children(fragment, separator = '')
    fragment.children.map { |f| generate(f, '') }.join(separator)
  end
end
