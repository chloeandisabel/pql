require File.join(File.expand_path(File.dirname(__FILE__)), 'event.rb')

class Entry

  def initialize(context, description, cause = [])
    @context = context
    @description = description
    @cause = cause
    @facts = []
    @id = UUID.new
  end

  attr_reader :events

  def method_missing(name, *args)
    if Event::Taxonomy.include? name
      @events.push args.merge(@context).merge(type: name, caused_by: @cause)
    else
      super
    end
  end

end
