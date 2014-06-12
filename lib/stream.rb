class Stream
  include Enumerable

  def initialize(events)
    @events = events
  end

  def each(&block)
    @events.each &block
  end
end
