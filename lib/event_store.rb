class EventStore
  CLIENT = Mysql2::Client.new(host: "localhost", username: "root", database: 'candi_development')
  
  EVENT_TABLE = 'facts'
  ENTRY_TABLE = 'fact_transactions'
  EVENT_COLUMNS = CLIENT.query("show columns from #{EVENT_TABLE}").map{|e| e['Field'].to_sym}
  ENTRY_COLUMNS = CLIENT.query("show columns from #{ENTRY_TABLE}").map{|e| e['Field'].to_sym}


  def self.query(attributes)
    query_attributes = attributes.map{|c, v| "`#{CLIENT.escape(c)}` = `#{CLIENT.escape(v)}`"}
    sql = "SELECT * FROM #{EVENT_TABLE} WHERE #{query_attributes.join(' AND ')};"
    result = CLIENT.query(sql, symbolize_keys: true)

    Stream.new(result.map{|row| Event.new(row)})
  end


  class Transaction
    
    def initialize(opts)
      @entries = []
      @persisted = false
      @atomic = opts[:atomic] || false
    end

    def <<(entry)
      raise if @persisted
      @entries << entry
    end

    def persist!
      raise if @persisted

      sql = @entries.reduce '' do |memo, entry|
        entry_insert = insert_statement_for entry, ENTRY_TABLE, ENTRY_COLUMNS
        
        events_insert = entry.events.reduce '' do |memo, event|
          event_insert = insert_statement_for event, EVENT_TABLE, EVENT_COLUMNS   
          memo + event_insert
        end

        memo + entry_insert + events_insert
      end

      @persisted = CLIENT.query sql
    end

    def persisted?
      @persisted
    end

    private

    def insert_statement_for(object, table, whitelist)
      columns = []
      values = []

      whitelist.each do |col|
        next unless object.has_key? col
        columns << col
        values << CLIENT.escape object[col]
      end

      "INSERT INTO #{table} (#{columns}) VALUES (#{values});"
    end

  end

end
