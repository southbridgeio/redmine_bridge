class OmniMarkup::RedmineTextile
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
        "\n"
      when 'b', 'strong'
        "*#{generate_children(fragment)}*"
      when 'i', 'em'
        "_#{generate_children(fragment)}_"
      when 'u'
        "+#{generate_children(fragment)}+"
      when 'strike'
        "-#{generate_children(fragment)}-"
      when 'h1'
        "h1. #{generate_children(fragment)}"
      when 'h2'
        "h2. #{generate_children(fragment)}"
      when 'h3'
        "h3. #{generate_children(fragment)}"
      when 'pre'
        "<pre>#{generate_children(fragment)}</pre>"
      when 'code'
        "<code#{%{ class="#{fragment[:class].sub('language-', '')}"} if fragment[:class]}>\n#{fragment.text}</code>"
      when 'ol', 'ul'
        generate_children(fragment)
      when 'li'
        if fragment.parent.name == 'ul'
          "* #{generate_children(fragment)}"
        elsif fragment.parent.name == 'ol'
          "# #{generate_children(fragment)}"
        else
          ''
        end
      when 'a'
        if fragment['href'].nil?
          fragment.text
        elsif fragment['title']
          %{["#{fragment.text} (#{fragment['title']})":#{fragment['href']}]}
        else
          %{["#{fragment.text}":#{fragment['href']}]}
        end
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
