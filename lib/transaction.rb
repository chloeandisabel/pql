class Transaction

  def initialize
    @entries = []
    @persisted = false
  end

  def <<(entry)
    raise if @persisted
    @entries << entry
  end

  def persist!
    raise if @persisted

    sql = @entries.reduce '' do |memo, entry|
      entry_insert = "INSERT INTO fact_transactions () VALUES ();"
      memo + entry_insert + entry.events.reduce do |memo, event|
        memo + "INSERT INTO facts () VALUES ();"
      end
    end

    @persisted = EventStore::CLIENT.query(sql)
  end

end