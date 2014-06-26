require 'treetop'
require_relative './node_extensions.rb'

class PQL::Parser

  Treetop.load(File.join(File.expand_path(File.dirname(__FILE__)), 'grammar.treetop'))
  @@parser = PQLParser.new


  def self.parse(expression)
    tree = @@parser.parse expression

    if tree.nil?
      raise Exception, "#{@@parser.failure_reason} at #{@@parser.failure_line}:#{@@parser.failure_column}"
    end

    tree
  end


  def self.print(root_node, offset = 0)
    unless root_node.syntax_node?
      text = root_node.text_value.gsub("\n",'').split(' ').join(' ').strip
      text = text[0, 100] + '...' if text.length > 100
      puts "#{'  ' * offset} #{root_node.class.name} - '#{text}' : #{root_node.interval}"

      root_node.elements.each {|node| self.print node, offset + 1 } if root_node.elements
    else
      root_node.elements.each {|node| self.print node, offset } if root_node.elements
    end
  end

end
