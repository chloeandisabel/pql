require_relative 'uuid.rb'
require_relative 'ontology.rb'

class Event

  def initialize(attrs)
    @attrs = attrs
    @attrs[:id] ||= UUID.new
  end

  def [](key)
    @attrs[key]
  end

  def types
    Ontology.lookup @attrs[:type]
  end

  def has_type?(type)
    types.include? type
  end

  def causes?(event)
    event[:caused_by].include? @attrs[:id]
  end

  def caused_by?(event)
    @attrs[:caused_by].include? event[:id]
  end

  def to_hash
    @attrs
  end

end