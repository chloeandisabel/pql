module PQL
  

  # events matched in one cardinal match of a single expression

  class Match

    def initialize(events = [], singular = false, join = nil)
      @events = events
      @singular = singular
      @join = join
    end

    attr_accessor :events, :singular, :join
    alias_method :singular?, :singular

    def value
      if singular? and events.length == 1
        events.first
      else
        events
      end
    end

    def ==(obj)
      value == obj
    end

  end


  # set of matches of a single expression each containing many events

  class MatchingExpressionApplication

    def initialize(matches = [], name = nil, join = nil)
      @matches = matches
      @name = name
      @join = join
    end

    attr_accessor :matches, :name, :join

    def successful?
      matches and matches.length > 0
    end

    def cardinality
      return 0 unless successful?
      return 1 if join

      matches.length
    end

    def named_matches
      hash = {}
      hash[name] = matches if name
      hash
    end
  end


  # set of all matches produced by applying a block to a stream

  class BlockApplication

    def initialize(expression_applications = [])
      @expression_applications = expression_applications
    end

    attr_accessor :expression_applications

    def named_matches
      return [] unless successful?

      # apply joins and convert to hashes
      map = {}
      applications = expression_applications.map do |application|
        matches = []

        if application.matches.any?
          application.matches.each do |match|
            hash = application.name ? Hash[application.name, match] : {}
            map[match] = hash

            if match.join
              map[match.join].merge! hash
            else
              matches << hash
            end
          end

          matches
        end

        matches << {} if matches.empty?

        matches
      end

      # take combinations of matches and merge named matches
      head, *tail = applications
      head.product(*tail).map do |matches| 
        matches.reduce &:merge
      end
    end

    def successful?
      expression_applications.all? {|application| application.successful?}
    end

    def cardinality
      return 0 unless successful?

      expression_applications.reduce 1 do |memo, result|
        memo * result.cardinality
      end
    end

    def each(&block)
      named_matches.each do |matches|
        block.call matches
      end
    end

  end

end