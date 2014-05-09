require File.join(File.expand_path(File.dirname(__FILE__)), '../lib/parser.rb')
require 'test/unit'


class TestMatching < Test::Unit::TestCase
  
  def test_match
    tree = Parser.parse 'MATCH LAST BY id WHERE type = "A" AND id < 4'
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'A'},
      {id: 4, type: 'A'}
    ]

    match = tree.match stream

    assert match.length == 1, 'expression should match one object'
    assert match[0][:id] == 3, 'expression should match object with id 3'
  end

  def test_match_2
    tree = Parser.parse 'MATCH LAST BY id WHERE type = "A" AND id < 4'
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B'},
      {id: 4, type: 'A'}
    ]

    match = tree.match stream
    
    assert match.length == 1, 'expression should match one object'
    assert match[0][:id] == 2, 'expression should match object with id 2'
  end

  def test_match_3
    tree = Parser.parse 'MATCH LAST 2 BY id WHERE type = "A" AND id <= 3'
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'A'},
      {id: 4, type: 'A'}
    ]

    match = tree.match stream
    
    assert match.length == 2, 'expression should match two objects'
    assert match[0][:id] == 3, 'expression should match object with id 3'
    assert match[1][:id] == 2, 'expression should match object with id 2'
  end

  def test_match_4
    tree = Parser.parse 'MATCH WHERE type IS "A" AND id NOT IN (applied_to WHERE type IS "B")'
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'A'},
      {id: 4, applied_to: 1, type: 'B'},
      {id: 4, applied_to: 3, type: 'B'}
    ]

    match = tree.match stream
    
    assert match.length == 1, 'expression should match one object'
    assert match[0][:id] == 2, 'expression should match object with id 2'
  end

  def test_match_5
    tree = Parser.parse(
      'MATCH WHERE
        type IN ["A", "B", "C"] AND
        id >= (MAX id WHERE type IS "D")'
    )
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'B'},
      {id: 3, type: 'C'},
      {id: 4, type: 'D'},
      {id: 5, type: 'A'},
      {id: 6, type: 'B'}
    ]

    match = tree.match stream

    assert match.length == 2, 'expression should match 2 objects'
    assert match[0][:id] == 5, 'expression should match object with id 5'
    assert match[1][:id] == 6, 'expression should match object with id 6'
  end

  def test_match_6
    tree = Parser.parse(
      'MATCH WHERE
        type = "A" AND
        id IN (target WHERE
          type = "B" AND
          caused_by IN (id WHERE type = "C")
        )'
    )
    stream = [
      {id: 1, type: 'A'},
      {id: 2, type: 'A'},
      {id: 3, type: 'B', target: 1, caused_by: 5},
      {id: 4, type: 'B', target: 2, caused_by: 6},
      {id: 5, type: 'C'},
      {id: 6, type: 'D'}
    ]

    match = tree.match stream

    assert match.length == 1, 'expression should match 1 objects'
    assert match[0][:id] == 1, 'expression should match object with id 1'
  end

end