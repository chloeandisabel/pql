class RuleSet

  def initialize(*rules)
    @rules = rules
  end

  def apply(stream)
    transaction = Transaction.new

    rules.each do |rule|
      rule.apply(stream).each do |entry|
        transaction << entry
        stream += entry.events
      end
    end

    transaction.persist!
  end

end