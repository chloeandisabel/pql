require File.join(File.expand_path(File.dirname(__FILE__)), 'node_extensions.rb')
require File.join(File.expand_path(File.dirname(__FILE__)), 'transaction.rb')


class Rule

  # defaults for dynamically defined methods

  @context = []
  @description = ''
  @pattern = PQL::Block.new '', 0..0
  @methods = {}
  @action = ->(){}


  # force subclasses to inherit class instance variables

  def self.inherited(subclass)
    [:@pattern, :@methods, :@action, :@context, :@description].each do |v|
      subclass.instance_variable_set(v, self.instance_variable_get(v))
    end
  end


  # class methods used to define subclasses

  def self.description(description)
    @description = description
  end

  def self.context(*columns)
    @context += columns
  end

  def self.pattern(pql)
    @pattern = PQL::Parser.parse pql
  end

  def self.method(name, &block)
    @methods ||= {}
    @methods[name] = block
  end

  def self.action(&block)
    @action = block
  end


  # instance methods

  def context_for(stream)
    ordered_stream = stream.sort_by{|e| e[:created_at]}
    self.class.instance_variable_get(:@context).reduce({}) do |context, column|
      source = ordered_stream.find{|f| f[column].present?}
      context[column] = source[column] if source
      context
    end
  end

  def description
    self.class.instance_variable_get :@description
  end

  def pattern
    self.class.instance_variable_get :@pattern
  end

  def action
    self.class.instance_variable_get :@action
  end

  def apply(stream)
    application = pattern.apply stream
    context = context_for stream

    application.each_match do |matches|
      cause = matches.map{|e| e[:id]}
      transaction = Transaction.new context, description, cause
      ActionContext.new(@methods, matches).instance_exec transaction, &action
      transaction
    end
  end


  # action context

  class ActionContext
    def initialize(methods, matches)
      @methods = methods
      @matches = matches
    end

    def method_missing(name, *args)
      return instance_eval(@methods[name]) if @methods.has_key? name
      return @matches[name] if @matches.has_key? name
      super
    end
  end

end
