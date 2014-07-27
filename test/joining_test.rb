require_relative '../lib/pql/parser.rb'
require_relative '../lib/pql/applications.rb'
require_relative '../lib/pql/node_extensions.rb'
require 'test/unit'


class TestMatching < Test::Unit::TestCase

  def test_each_with_no_matching_events
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH EACH AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == false, 'expression should not match stream'
  end

  def test_all_with_no_matching_events
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH EACH AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == false, 'expression should not match stream'
  end

  def test_any_with_no_matching_events
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH ANY AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 2, 'expression should match twice'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: []
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: []
      },
    ], 'expression should match twice selecting selecting only item')
  end

  def test_each_with_equal_numbers
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH EACH AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
      {id: 3, type: 'TaxEntry', applied_to: 1},
      {id: 4, type: 'TaxEntry', applied_to: 2},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 2, 'expression should match twice'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: {id: 3, type: 'TaxEntry', applied_to: 1}
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: {id: 4, type: 'TaxEntry', applied_to: 2}
      },
    ], 'expression should match twice selecting selecting item and tax')
  end

  def test_all_with_equal_numbers
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH ALL AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
      {id: 3, type: 'TaxEntry', applied_to: 1},
      {id: 4, type: 'TaxEntry', applied_to: 2},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 2, 'expression should match twice'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: [{id: 3, type: 'TaxEntry', applied_to: 1}]
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: [{id: 4, type: 'TaxEntry', applied_to: 2}]
      },
    ], 'expression should match twice selecting selecting item and tax')
  end

  def test_any_with_equal_numbers
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH ANY AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
      {id: 3, type: 'TaxEntry', applied_to: 1},
      {id: 4, type: 'TaxEntry', applied_to: 2},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 2, 'expression should match twice'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: [{id: 3, type: 'TaxEntry', applied_to: 1}]
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: [{id: 4, type: 'TaxEntry', applied_to: 2}]
      },
    ], 'expression should match twice selecting selecting item and tax')
  end

  def test_each_with_more_on_left
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH EACH AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
      {id: 3, type: 'ItemSelected'},
      {id: 4, type: 'TaxEntry', applied_to: 1},
      {id: 5, type: 'TaxEntry', applied_to: 2},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 3, 'expression should match twice'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: {id: 4, type: 'TaxEntry', applied_to: 1}
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: {id: 5, type: 'TaxEntry', applied_to: 2}
      },
      {
        item: {id: 3, type: 'ItemSelected'},
      }
    ], 'expression should match three times selecting selecting item and tax')
  end

  def test_all_with_more_on_left
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH ALL AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
      {id: 3, type: 'ItemSelected'},
      {id: 4, type: 'TaxEntry', applied_to: 1},
      {id: 5, type: 'TaxEntry', applied_to: 2},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 3, 'expression should match twice'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: [{id: 4, type: 'TaxEntry', applied_to: 1}]
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: [{id: 5, type: 'TaxEntry', applied_to: 2}]
      },
      {
        item: {id: 3, type: 'ItemSelected'},
      }
    ], 'expression should match three times selecting selecting item and tax')
  end

  def test_any_with_more_on_left
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH ANY AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
      {id: 3, type: 'ItemSelected'},
      {id: 4, type: 'TaxEntry', applied_to: 1},
      {id: 5, type: 'TaxEntry', applied_to: 2},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 3, 'expression should match three times'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: [{id: 4, type: 'TaxEntry', applied_to: 1}]
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: [{id: 5, type: 'TaxEntry', applied_to: 2}]
      },
      {
        item: {id: 3, type: 'ItemSelected'}
      },
    ], 'expression should match three times selecting selecting tax twice')
  end

  def test_each_with_more_on_right
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH EACH AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
      {id: 3, type: 'TaxEntry', applied_to: 1},
      {id: 4, type: 'TaxEntry', applied_to: 2},
      {id: 5, type: 'TaxEntry', applied_to: nil},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 2, 'expression should match twice'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: {id: 3, type: 'TaxEntry', applied_to: 1}
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: {id: 4, type: 'TaxEntry', applied_to: 2}
      },
    ], 'expression should match twice selecting selecting item and tax')
  end

  def test_all_with_more_on_right
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH ALL AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
      {id: 3, type: 'TaxEntry', applied_to: 1},
      {id: 4, type: 'TaxEntry', applied_to: 2},
      {id: 5, type: 'TaxEntry', applied_to: nil},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 2, 'expression should match twice'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: [{id: 3, type: 'TaxEntry', applied_to: 1}]
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: [{id: 4, type: 'TaxEntry', applied_to: 2}]
      },
    ], 'expression should match twice selecting selecting item and tax')
  end


  def test_any_with_more_on_right
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH ANY AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
      {id: 3, type: 'TaxEntry', applied_to: 1},
      {id: 4, type: 'TaxEntry', applied_to: 2},
      {id: 5, type: 'TaxEntry', applied_to: nil},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 2, 'expression should match twice'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: [{id: 3, type: 'TaxEntry', applied_to: 1}]
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: [{id: 4, type: 'TaxEntry', applied_to: 2}]
      },
    ], 'expression should match twice selecting selecting item and tax')
  end

  def test_multiple_joins
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH EACH AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
      MATCH EACH AS credit WHERE type IS "CreditEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
      {id: 3, type: 'TaxEntry', applied_to: 1},
      {id: 4, type: 'TaxEntry', applied_to: 2},
      {id: 5, type: 'CreditEntry', applied_to: 1},
      {id: 6, type: 'CreditEntry', applied_to: 2},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 2, 'expression should match twice'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: {id: 3, type: 'TaxEntry', applied_to: 1},
        credit: {id: 5, type: 'CreditEntry', applied_to: 1}
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: {id: 4, type: 'TaxEntry', applied_to: 2},
        credit: {id: 6, type: 'CreditEntry', applied_to: 2}
      },
    ], 'expression should match twice selecting selecting item and tax')
  end

  def test_complex_selection
    pql = '
      MATCH EACH AS item WHERE type IS "ItemSelected";
      MATCH FIRST IN ORDER BY id GROUPED BY applied_to AS tax WHERE type IS "TaxEntry" JOINING item WHERE applied_to = item.id;
    '

    stream = [
      {id: 1, type: 'ItemSelected'},
      {id: 2, type: 'ItemSelected'},
      {id: 3, type: 'ItemSelected'},
      {id: 4, type: 'TaxEntry', applied_to: 1},
      {id: 5, type: 'TaxEntry', applied_to: 2},
      {id: 6, type: 'TaxEntry', applied_to: 1},
      {id: 7, type: 'TaxEntry', applied_to: 2},
    ]

    application = PQL::Parser.parse(pql).apply(stream)

    assert application.successful? == true, 'expression should match stream'
    assert application.cardinality == 3, 'expression should match twice'
    assert(application.named_matches == [
      {
        item: {id: 1, type: 'ItemSelected'},
        tax: {id: 4, type: 'TaxEntry', applied_to: 1}
      },
      {
        item: {id: 2, type: 'ItemSelected'},
        tax: {id: 5, type: 'TaxEntry', applied_to: 2}
      },
      {
        item: {id: 3, type: 'ItemSelected'}
      }
    ], 'expression should match three times selecting selecting tax twice')
  end
end