class EventStore
  CLIENT = Mysql2::Client.new(host: "localhost", username: "root", database: 'candi_development')
  EVENT_COLUMNS = CLIENT.query('show columns from facts').map{|e| e['Field']}

  def self.query(params)
    sql = "SELECT * FROM facts WHERE #{params.map{|c, v| "`#{CLIENT.escape(c)}` = `#{CLIENT.escape(v)}`"}.join(' AND ')};"
    Stream.new CLIENT.query(sql).map{|result| Event.new(result)}
  end
end
