require File.join(File.expand_path(File.dirname(__FILE__)), '../lib/parser.rb')
require 'test/unit'


class TestMatching < Test::Unit::TestCase

  def test_match_all
    pql = 'MATCH ALL AS a WHERE type IS "A" AND id < 3'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'A'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert application.named_matches[0] == {a: [{id: 1, type: 'A'}, {id: 2, type: 'A'}]}, 'expression should match 2 events'
  end

  def test_match_each
    pql = 'MATCH EACH AS a WHERE type IS "A" AND id < 3'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'A'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 2, 'expression should match two times'
    assert application.named_matches[0] == {a: [{id: 1, type: 'A'}]}, 'expression should match 1 event'
    assert application.named_matches[1] == {a: [{id: 2, type: 'A'}]}, 'expression should match 1 event'
  end

  def test_match_cardinality
    pql = 'MATCH ALL AS a WHERE type IS "A";
           MATCH EACH AS b WHERE type IS "B";'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B'},
      {id: 4, type: 'B'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 2, 'expression should match two times'
    assert application.named_matches[0] == {a: [{id: 1, type: 'A'}, {id: 2, type: 'A'}], b: [{id: 3, type: 'B'}]}, 'expression should match 3 events'
    assert application.named_matches[1] == {a: [{id: 1, type: 'A'}, {id: 2, type: 'A'}], b: [{id: 4, type: 'B'}]}, 'expression should match 3 events'
  end

  def test_match_cardinality_2
    pql = 'MATCH EACH AS a WHERE type IS "A";
           MATCH EACH AS b WHERE type IS "B";'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B'},
      {id: 4, type: 'B'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)
    
    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 4, 'expression should match four times'
    assert application.named_matches[0] == {a: [{id: 1, type: 'A'}], b: [{id: 3, type: 'B'}]}, 'expression should match 2 events'
    assert application.named_matches[1] == {a: [{id: 1, type: 'A'}], b: [{id: 4, type: 'B'}]}, 'expression should match 2 events'
    assert application.named_matches[2] == {a: [{id: 2, type: 'A'}], b: [{id: 3, type: 'B'}]}, 'expression should match 2 events'
    assert application.named_matches[3] == {a: [{id: 2, type: 'A'}], b: [{id: 4, type: 'B'}]}, 'expression should match 2 events'
  end

  def test_non_match
    pql = 'MATCH ALL AS c WHERE type IS "C"';
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == false, 'expression should not match stream'
    assert application.cardinality == 0, 'expression match 0 times'
    assert application.named_matches == [], 'should match 0 events'
  end

  def test_non_match_2
    pql = 'MATCH ALL AS c WHERE type IS "C";
           MATCH ALL AS b WHERE type IS "B";'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B'},
      {id: 4, type: 'B'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == false, 'expression should not match stream'
    assert application.cardinality == 0, 'expression match 0 times'
    assert application.named_matches == [], 'should match 0 events'
  end

  def test_match_none
    pql = 'MATCH NONE WHERE type IS "A";
           MATCH EACH AS b WHERE type IS "B";'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B'},
      {id: 4, type: 'B'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == false, 'expression should not match stream'
    assert application.cardinality == 0, 'expression match 0 times'
    assert application.named_matches == [], 'should match 0 events'
  end

  def test_match_any
    pql = 'MATCH ANY AS a WHERE type IS "A" AND id < 3'
    
    stream = [
      {id: 1, type: 'B'},
      {id: 2, type: 'B'},
      {id: 3, type: 'B'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert application.named_matches[0] == {}, 'expression should match no events'
  end

  def test_match_any_2
    pql = 'MATCH ANY AS a WHERE type IS "A" AND id < 3'
    
    stream = [
      {id: 1, type: 'B'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert application.named_matches[0] == {a: [{id: 2, type: 'A'}]}, 'expression should match one event'
  end

  def test_unnamed_match
    pql = 'MATCH LAST BY id WHERE type = "A"'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)
    
    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert application.named_matches == [{}], 'expression should return an empty object as named match'
  end

  def test_match
    pql = 'MATCH LAST BY id AS a WHERE type = "A" AND id < 4'

    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B'},
      {id: 4, type: 'A'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert application.named_matches == [{a: [{id: 2, type: 'A'}]}], 'expression should match object with id 2'
  end

  def test_match_2
    pql = 'MATCH LAST 2 BY id AS a WHERE type = "A" AND id <= 3'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'A'},
      {id: 4, type: 'A'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert application.named_matches == [{a: [{id: 3, type: 'A'}, {id: 2, type: 'A'}]}], 'expression should match 3 events'
  end

  def test_match_3
    pql = 'MATCH ALL AS a WHERE type IS "A" AND id NOT IN (applied_to WHERE type IS "B")'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'A'},
      {id: 4, applied_to: 1, type: 'B'},
      {id: 4, applied_to: 3, type: 'B'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)
    
    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert application.named_matches == [{a: [{id: 2, type: 'A'}]}], 'expression should match event w/ id 2'
  end

  def test_match_4
    pql = '
      MATCH ALL AS abc WHERE
        type IN ["A", "B", "C"] AND
        id >= (MAX id WHERE type IS "D")
    '

    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'B'},
      {id: 3, type: 'C'},
      {id: 4, type: 'D'},
      {id: 5, type: 'A'},
      {id: 6, type: 'B'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert application.named_matches == [{abc: [{id: 5, type: 'A'}, {id: 6, type: 'B'}]}], 'expression should match events w/ id 5 and 6'
  end

  def test_match_5
    pql = '
      MATCH ALL AS a WHERE
        type = "A" AND
        id IN (target WHERE
          type = "B" AND
          caused_by IN (id WHERE type = "C")
        )
    '

    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B', target: 1, caused_by: 5},
      {id: 4, type: 'B', target: 2, caused_by: 6},
      {id: 5, type: 'C'},
      {id: 6, type: 'D'}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert application.named_matches == [{a: [{id: 1, type: 'A'}]}], 'expression should match object with id 1'
  end

  def test_match_6
    pql = 'MATCH ALL AS a WHERE type = "A" AND (target WHERE type = "B") INCLUDES id'

    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B'},
      {id: 4, type: 'B', target: 2},
      {id: 5, type: 'B', target: 3},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert application.named_matches == [{a: [{id: 2, type: 'A'}]}], 'expression should match object with id 2'
  end

  def test_named_matches
    pql = '
      MATCH FIRST BY id AS a WHERE type IS "A";
      MATCH LAST BY id AS b WHERE type IS "B";
      MATCH ALL AS c WHERE type IS "C";
    '

    stream = [
      {id: 1, type: "A"},
      {id: 2, type: "A"},
      {id: 3, type: "B"},
      {id: 4, type: "B"},
      {id: 5, type: "C"},
      {id: 6, type: "C"},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert(application.named_matches == [{
      a: [{id: 1, type: 'A'}],
      b: [{id: 4, type: 'B'}],
      c: [{id: 5, type: 'C'}, {id: 6, type: 'C'}]
    }], 'expression should match object with id 2')

  end

  def test_references
    pql = '
      MATCH EACH AS credit WHERE
        type IS "CreditAwarded"
        AND amount > (SUM amount WHERE
          type IS "CreditRedeemed"
          AND applied_to = ^id
        );
    '
    stream = [
      {id: 1, type: "CreditAwarded", amount: 2.0},
      {id: 2, type: "CreditAwarded", amount: 2.0},
      {id: 3, type: "CreditAwarded", amount: 2.0},
      {id: 4, type: "CreditRedeemed", amount: 1.0, applied_to: 1},
      {id: 5, type: "CreditRedeemed", amount: 1.0, applied_to: 1},
      {id: 6, type: "CreditRedeemed", amount: 1.0, applied_to: 2}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 2, 'expression should match two times'
    assert(application.named_matches == [
      {credit: [{id: 2, type: 'CreditAwarded', amount: 2.0}]},
      {credit: [{id: 3, type: 'CreditAwarded', amount: 2.0}]}
    ], 'expression should match twice selecting credits w/ ids 2 and 3')
  end

  def test_multi_level_references
    pql = '
      MATCH EACH AS credit WHERE
        type IS "CreditAwarded"
        AND amount > (SUM amount WHERE
          type IS "CreditRedeemed"
          AND credit_id = ^credit_id
          AND (COUNT id WHERE
            type IS "CreditRedemptionCancelled"
            AND redemption_id = ^id
            AND credit_id = ^^credit_id
          ) = 0
        );
    '
    stream = [
      {id: 1, type: "CreditAwarded", amount: 2.0, credit_id: 1},
      {id: 2, type: "CreditAwarded", amount: 2.0, credit_id: 2},
      {id: 4, type: "CreditRedeemed", amount: 1.0, credit_id: 1},
      {id: 5, type: "CreditRedeemed", amount: 1.0, credit_id: 1},
      {id: 6, type: "CreditRedeemed", amount: 1.0, credit_id: 2},
      {id: 7, type: "CreditRedeemed", amount: 1.0, credit_id: 2},

      # should not be counted because credit id is wrong
      {id: 8, type: "CreditRedemptionCancelled", redemption_id: 4, credit_id: 3},
      
      # should be counted and allow the fact w/ id 2 to match as credit
      {id: 9, type: "CreditRedemptionCancelled", redemption_id: 6, credit_id: 2}
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.matches? == true, 'expression should match stream'
    assert application.cardinality == 1, 'expression should match one time'
    assert(application.named_matches == [
      {credit: [{id: 2, type: 'CreditAwarded', amount: 2.0, credit_id: 2}]},
    ], 'expression should match twice selecting credits w/ ids 2 and 3')
  end

end