class Event

  def initialize(attrs)
    @attrs = attrs
  end

  def [](key)
    @attrs[key]
  end

  def types
    Taxonomy.lookup @attrs[:type]
  end


  class Taxonomy

    @@directory = {}

    def self.define(&block)
      class_eval &block
    end

    # define an event type w/ multiple inheritance
    def self.type(name, parents = [])
      @@directory[name] = parents
    end

    # look up exhaustive list of types a type belongs to
    def self.lookup(name)
      @@directory[name].reduce Set.new([name]) do |memo, type|
        memo.merge(@@directory.has_key?(type) ? self.lookup(type) : [type])
      end
    end

    # return true if an type has been defined
    def self.include?(name)
      @@directory.has_key? name
    end

  end

end