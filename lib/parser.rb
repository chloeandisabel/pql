require 'treetop'
require File.join(File.expand_path(File.dirname(__FILE__)), 'node_extensions.rb')

class Parser
  
  Treetop.load(File.join(File.expand_path(File.dirname(__FILE__)), 'grammar.treetop'))
  @@parser = PatternDescriptionParser.new


  def self.parse(data)
    tree = @@parser.parse data

    if tree.nil?
      raise Exception, "parse error at offset: #{@@parser.index}"
    end

    self.prune_tree tree

    tree
  end


  def self.print_tree(root_node, offset = 0)
    puts "#{'  ' * offset} #{root_node.class.name} - #{root_node.interval} : '#{root_node.text_value}'" 
    root_node.elements.each {|node| self.print_tree node, offset + 1 } if root_node.elements
  end


  private


  def self.prune_tree(root_node)
    return unless root_node.elements

    # splice children of syntax nodes onto root node
    root_node.elements.each do |node|
      next unless node.elements and node.syntax_node?
      node.elements.each do |child_node|
        root_node.elements << child_node
        child_node.parent = root_node
      end
      node.elements.delete_if {true}
    end

    # delete syntax nodes
    root_node.elements.delete_if {|node| node.syntax_node? }
    
    # recursively apply to child nodes
    root_node.elements.each {|node| self.prune_tree(node) }
  end

end