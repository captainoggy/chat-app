require_dependency "onpdiff"

class DiscourseDiff

  MAX_DIFFERENCE = 200

  def initialize(before, after)
    @before = before
    @after = after

    @block_by_block_diff = ONPDiff.new(tokenize_html_blocks(@before), tokenize_html_blocks(@after)).diff
    @line_by_line_diff = ONPDiff.new(tokenize_line(@before), tokenize_line(@after)).short_diff
  end

  def inline_html
    i = 0
    inline = []
    while i < @block_by_block_diff.length
      op_code = @block_by_block_diff[i][1]
      if op_code == :common then inline << @block_by_block_diff[i][0]
      else
        if op_code == :delete
          opposite_op_code = :add
          klass = "del"
          first = i
          second = i + 1
        else
          opposite_op_code = :delete
          klass = "ins"
          first = i + 1
          second = i
        end

        if i + 1 < @block_by_block_diff.length && @block_by_block_diff[i + 1][1] == opposite_op_code
          diff = ONPDiff.new(tokenize_html(@block_by_block_diff[first][0]), tokenize_html(@block_by_block_diff[second][0])).diff
          inline << generate_inline_html(diff)
          i += 1
        else
          inline << add_class_or_wrap_in_tags(@block_by_block_diff[i][0], klass)
        end
      end
      i += 1
    end

    "<div class=\"inline-diff\">#{inline.join}</div>"
  end

  def side_by_side_html
    i = 0
    left, right = [], []
    while i < @block_by_block_diff.length
      op_code = @block_by_block_diff[i][1]
      if op_code == :common
        left << @block_by_block_diff[i][0]
        right << @block_by_block_diff[i][0]
      else
        if op_code == :delete
          opposite_op_code = :add
          side = left
          klass = "del"
          first = i
          second = i + 1
        else
          opposite_op_code = :delete
          side = right
          klass = "ins"
          first = i + 1
          second = i
        end

        if i + 1 < @block_by_block_diff.length && @block_by_block_diff[i + 1][1] == opposite_op_code
          diff = ONPDiff.new(tokenize_html(@block_by_block_diff[first][0]), tokenize_html(@block_by_block_diff[second][0])).diff
          deleted, inserted = generate_side_by_side_html(diff)
          left << deleted
          right << inserted
          i += 1
        else
          side << add_class_or_wrap_in_tags(@block_by_block_diff[i][0], klass)
        end
      end
      i += 1
    end

    "<div class=\"span8\">#{left.join}</div><div class=\"span8 offset1\">#{right.join}</div>"
  end

  def side_by_side_text
    i = 0
    table = ["<table class=\"markdown\">"]
    while i < @line_by_line_diff.length
      table << "<tr>"
      op_code = @line_by_line_diff[i][1]
      if op_code == :common
        table << "<td>#{CGI::escapeHTML(@line_by_line_diff[i][0])}</td>"
        table << "<td>#{CGI::escapeHTML(@line_by_line_diff[i][0])}</td>"
      else
        if op_code == :delete
          opposite_op_code = :add
          first = i
          second = i + 1
        else
          opposite_op_code = :delete
          first = i + 1
          second = i
        end

        if i + 1 < @line_by_line_diff.length && @line_by_line_diff[i + 1][1] == opposite_op_code
          before_tokens, after_tokens = tokenize_text(@line_by_line_diff[first][0]), tokenize_text(@line_by_line_diff[second][0])
          if (before_tokens.length - after_tokens.length).abs > MAX_DIFFERENCE
            before_tokens, after_tokens = tokenize_line(@line_by_line_diff[first][0]), tokenize_line(@line_by_line_diff[second][0])
          end
          diff = ONPDiff.new(before_tokens, after_tokens).short_diff
          deleted, inserted = generate_side_by_side_text(diff)
          table << "<td class=\"diff-del\">#{deleted.join}</td>"
          table << "<td class=\"diff-ins\">#{inserted.join}</td>"
          i += 1
        else
          if op_code == :delete
            table << "<td class=\"diff-del\">#{CGI::escapeHTML(@line_by_line_diff[i][0])}</td>"
            table << "<td></td>"
          else
            table << "<td></td>"
            table << "<td class=\"diff-ins\">#{CGI::escapeHTML(@line_by_line_diff[i][0])}</td>"
          end
        end
      end
      table << "</tr>"
      i += 1
    end
    table << "</table>"

    table.join
  end

  private

  def tokenize_line(text)
    text.scan(/[^\r\n]+[\r\n]*/)
  end

  def tokenize_text(text)
    t, tokens = [], []
    i = 0
    while i < text.length
      if text[i] =~ /\w/
        t << text[i]
      elsif text[i] =~ /[ \t]/ && t.join =~ /^\w+$/
        begin
          t << text[i]
          i += 1
        end while i < text.length && text[i] =~ /[ \t]/
        i -= 1
        tokens << t.join
        t = []
      else
        tokens << t.join if t.length > 0
        tokens << text[i]
        t = []
      end
      i += 1
    end
    tokens << t.join if t.length > 0
    tokens
  end

  def tokenize_html_blocks(html)
    Nokogiri::HTML.fragment(html).search("./*").map(&:to_html)
  end

  def tokenize_html(html)
    HtmlTokenizer.tokenize(html)
  end

  def add_class_or_wrap_in_tags(html_or_text, klass)
    index_of_next_chevron = html_or_text.index(">")
    if html_or_text.length > 0 && html_or_text[0] == '<' && index_of_next_chevron
      index_of_class = html_or_text.index("class=")
      if index_of_class.nil? || index_of_class > index_of_next_chevron
        # we do not have a class for the current tag
        # add it right before the ">"
        html_or_text.insert(index_of_next_chevron, " class=\"diff-#{klass}\"")
      else
        # we have a class, insert it at the beginning
        html_or_text.insert(index_of_class + "class=".length + 1, "diff-#{klass} ")
      end
    else
      "<#{klass}>#{html_or_text}</#{klass}>"
    end
  end

  def generate_inline_html(diff)
    inline = []
    diff.each do |d|
      case d[1]
      when :common then inline << d[0]
      when :delete then inline << add_class_or_wrap_in_tags(d[0], "del")
      when :add then inline << add_class_or_wrap_in_tags(d[0], "ins")
      end
    end
    inline
  end

  def generate_side_by_side_html(diff)
    deleted, inserted = [], []
    diff.each do |d|
      case d[1]
      when :common
        deleted << d[0]
        inserted << d[0]
      when :delete then deleted << add_class_or_wrap_in_tags(d[0], "del")
      when :add then inserted << add_class_or_wrap_in_tags(d[0], "ins")
      end
    end
    [deleted, inserted]
  end

  def generate_side_by_side_text(diff)
    deleted, inserted = [], []
    diff.each do |d|
      case d[1]
      when :common
        deleted << d[0]
        inserted << d[0]
      when :delete then deleted << "<del>#{CGI::escapeHTML(d[0])}</del>"
      when :add then inserted << "<ins>#{CGI::escapeHTML(d[0])}</ins>"
      end
    end
    [deleted, inserted]
  end

  class HtmlTokenizer < Nokogiri::XML::SAX::Document

    attr_accessor :tokens

    def initialize
      @tokens = []
    end

    def self.tokenize(html)
      me = new
      parser = Nokogiri::HTML::SAX::Parser.new(me)
      parser.parse("<html><body>#{html}</body></html>")
      me.tokens
    end

    USELESS_TAGS = %w{html body}
    def start_element(name, attributes = [])
      return if USELESS_TAGS.include?(name)
      attrs = attributes.map { |a| " #{a[0]}=\"#{a[1]}\"" }.join
      @tokens << "<#{name}#{attrs}>"
    end

    AUTOCLOSING_TAGS = %w{area base br col embed hr img input meta}
    def end_element(name)
      return if USELESS_TAGS.include?(name) || AUTOCLOSING_TAGS.include?(name)
      @tokens << "</#{name}>"
    end

    def characters(string)
      @tokens.concat string.scan(/(\W|\w+[ \t]*)/).flatten
    end

  end

end
