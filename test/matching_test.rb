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

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 1, 'expression should match one time'
    assert match_set.named_matches[0] == {a: [{id: 1, type: 'A'}, {id: 2, type: 'A'}]}, 'expression should match 2 events'
  end

  def test_match_each
    pql = 'MATCH EACH AS a WHERE type IS "A" AND id < 3'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'A'}
    ]

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 2, 'expression should match two times'
    assert match_set.named_matches[0] == {a: [{id: 1, type: 'A'}]}, 'expression should match 1 event'
    assert match_set.named_matches[1] == {a: [{id: 2, type: 'A'}]}, 'expression should match 1 event'
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

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 2, 'expression should match two times'
    assert match_set.named_matches[0] == {a: [{id: 1, type: 'A'}, {id: 2, type: 'A'}], b: [{id: 3, type: 'B'}]}, 'expression should match 3 events'
    assert match_set.named_matches[1] == {a: [{id: 1, type: 'A'}, {id: 2, type: 'A'}], b: [{id: 4, type: 'B'}]}, 'expression should match 3 events'
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

    match_set = Parser.parse(pql).apply(stream)
    
    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 4, 'expression should match four times'
    assert match_set.named_matches[0] == {a: [{id: 1, type: 'A'}], b: [{id: 3, type: 'B'}]}, 'expression should match 2 events'
    assert match_set.named_matches[1] == {a: [{id: 1, type: 'A'}], b: [{id: 4, type: 'B'}]}, 'expression should match 2 events'
    assert match_set.named_matches[2] == {a: [{id: 2, type: 'A'}], b: [{id: 3, type: 'B'}]}, 'expression should match 2 events'
    assert match_set.named_matches[3] == {a: [{id: 2, type: 'A'}], b: [{id: 4, type: 'B'}]}, 'expression should match 2 events'
  end

  def test_non_match
    pql = 'MATCH ALL AS c WHERE type IS "C"';
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B'}
    ]

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == false, 'expression should not match stream'
    assert match_set.cardinality == 0, 'expression match 0 times'
    assert match_set.named_matches == [], 'should match 0 events'
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

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == false, 'expression should not match stream'
    assert match_set.cardinality == 0, 'expression match 0 times'
    assert match_set.named_matches == [], 'should match 0 events'
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

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == false, 'expression should not match stream'
    assert match_set.cardinality == 0, 'expression match 0 times'
    assert match_set.named_matches == [], 'should match 0 events'
  end


  def test_unnamed_match
    pql = 'MATCH LAST BY id WHERE type = "A"'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'}
    ]

    match_set = Parser.parse(pql).apply(stream)
    
    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 1, 'expression should match one time'
    assert match_set.named_matches == [{}], 'expression should return an empty object as named match'
  end

  def test_match
    pql = 'MATCH LAST BY id AS a WHERE type = "A" AND id < 4'

    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B'},
      {id: 4, type: 'A'}
    ]

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 1, 'expression should match one time'
    assert match_set.named_matches == [{a: [{id: 2, type: 'A'}]}], 'expression should match object with id 2'
  end

  def test_match_2
    pql = 'MATCH LAST 2 BY id AS a WHERE type = "A" AND id <= 3'
    
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'A'},
      {id: 4, type: 'A'}
    ]

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 1, 'expression should match one time'
    assert match_set.named_matches == [{a: [{id: 3, type: 'A'}, {id: 2, type: 'A'}]}], 'expression should match 3 events'
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

    match_set = Parser.parse(pql).apply(stream)
    
    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 1, 'expression should match one time'
    assert match_set.named_matches == [{a: [{id: 2, type: 'A'}]}], 'expression should match event w/ id 2'
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

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 1, 'expression should match one time'
    assert match_set.named_matches == [{abc: [{id: 5, type: 'A'}, {id: 6, type: 'B'}]}], 'expression should match events w/ id 5 and 6'
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

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 1, 'expression should match one time'
    assert match_set.named_matches == [{a: [{id: 1, type: 'A'}]}], 'expression should match object with id 1'
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

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 1, 'expression should match one time'
    assert match_set.named_matches == [{a: [{id: 2, type: 'A'}]}], 'expression should match object with id 2'
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

    match_set = Parser.parse(pql).apply(stream)

    assert match_set.matches? == true, 'expression should match stream'
    assert match_set.cardinality == 1, 'expression should match one time'
    assert(match_set.named_matches == [{
      a: [{id: 1, type: 'A'}],
      b: [{id: 4, type: 'B'}],
      c: [{id: 5, type: 'C'}, {id: 6, type: 'C'}]
    }], 'expression should match object with id 2')

  end

end