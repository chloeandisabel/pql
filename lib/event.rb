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


  class Ontology

    @@directory = {}

    # return a list of all defined types
    def self.types
      @@directory.keys
    end
    
    # return true if a type has been defined
    def self.include?(name)
      @@directory.has_key? name
    end

    # look up exhaustive list of all types a given type belongs to
    def self.lookup(name)
      @@directory[name].reduce Set.new([name]) do |memo, type|
        memo.merge(@@directory.has_key?(type) ? self.lookup(type) : [type])
      end
    end

    def self.define(&block)
      class_eval &block
    end

    private

    # define an event type w/ multiple inheritance
    def self.type(name, parents = [])
      @@directory[name] = parents
    end

  end

end