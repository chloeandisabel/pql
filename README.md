PQL
===

*Pattern Query Language*

A small declarative language for describing patterns in a stream of events.

---


Matching Expressions
--------------------

Matching expressions match the presence or absence of a specific set of events in a stream.  

    MATCH ALL AS pageviews WHERE type IS 'PageViewed'

When applied to a stream, matching expressions produce a set of zero or more *matches*, each consisting zero or more events.  An expression is said to match a stream if its set of matches has at least one member.

A matching expression can be broken down into the following parts:

- match keyword: `MATCH`
- selective expression: `ALL`
- naming expression: `AS pageviews`
- filtering expression: `WHERE type IS 'PageViewed'`



### Match Keyword

matching expressions always begin with the word `MATCH`



### Selective Expression

Matching expressions can match the same stream of events multiple times - an expression's *cardinality* with respect to a stream is the number of distinct sets of events it matches in the stream.

A selective expression transforms the single set of filtered events into one or more *matches*, determining its cardinality.

In the given example `ALL` is the most basic selective expression, it will produce one match, selecting all of the filtered events and giving the expression a cardinality of one.

Selective expressions can be made up of any number of subexpressions, which compose from right to left.  Each subexpression is applied separately to each of the matches produced by the preceding expression.

For example, the following matching epxression selects each event with the highest priority within the group of 'PromotionApplied' events sharing its color.

    MATCH FIRST IN ORDER BY priority GROUPED BY color AS promotion WHERE TYPE 'PromotionApplied'
    
This selective expression here is `FIRST IN ORDER BY priority GROUPED BY color`, and its three subexpressions are `FIRST`, `IN ORDER BY priority`, and `GROUPED BY color`. 

The rightmost subexpression, `GROUPED BY color` is applied first, and splits the events into matches by their color attribute.  Next, the `IN ORDER BY priority` subexpression is applied and orders the events within each match by their priority.  Finally, the `FIRST` subexpression is applied and selects only the first event within each match. 


There are three types of selective subexpressions:

  - **Ordering Expressions:** ordering expressions reorder events within each match without changing the number of matches or the number of events in each match.
  
    - `IN ORDER BY column` sorts events within each match from lowest to highest
    - `IN DESCENDING ORDER BY column` sorts events within each match from highest to lowest.

  - **Limiting Expressions:** limiting expressions select subsets of events within each match without changing the overall number of matches.
    
    - `FIRST`, `LAST`, `FIRST n`, or `LAST n`

  - **Cardinality Expressions:** cardinality expressions determine the number of matches.

    - `ALL` is the default cardinality - it matches one time selecting all of the events meeting the conditions.
    - `EACH` matches once for each event in the stream, selecting one event in each match.
    - `ANY` always matches one time, whether or not any events in the stream meet the conditions.  If any events do meet the conditions, it selects them, otherwise it selects no events.
    - `NONE` matches one time and selects no events.  It matches only if no events in the stream meet the conditions.
    - `GROUPED BY column` matches once for each unique value of a column, selecting the set of events sharing that value.



### Naming Expression

Matches can be optionally named by including a naming expression immediately following the cardinality operator.  In the first example, `MATCH ALL AS pageviews WHERE type IS 'PageViewed'`, `AS pageviews` names the match 'pageviews'.  

A naming expression consists of the `AS` keyword followed by a match name.  Match names are not quoted and can contain upper and lower case letters and underscores.



### Filtering Expressions

Filtering expressions are made up of a set of conditions and begin with the `WHERE` keyword.  Conditions are ordered using `()` and combined using the boolean operators `AND` and `OR`.  To find matching events, an expression checks each fact in the stream individually against its conditions - selecting the events for which the conditions are true.


### comparisons

Comparisons are the most basic condition, and follow the format `left value` `comparison operator` `right value`


#### Values

Values can be references to the value of a column on the event currently being considered (the *subject event*), literal values, or references to values of other events in the stream (*value expressions*).

- **Subject Event Columns:** subject event columns refer to values on the subject event.  For example, in the condition `WHERE type IS 'PageViewed'`, `type` is a subject event column and refers to the value of the column named `type` on the subject event.  The condition will be true for subject event `{type: 'PageViewed'}`.  Column names can consist of lower and uppercase letters and underscores.


- **Literals:**  literals express a value directly without reference to the subject event or other  events in the stream.
    - **Integer Literals:** `1`, `12`, or `9001`
    - **Floating Point Literals:** `1.1`, `3.14`, or `99.999`
    - **String Literals:** delimited by single or double quotes. `"Etzion & Niblett"` or `'Oprah Winfrey'`
    - **Regular Expression Literals:** `/^abcd/` or `/[0-9]+/`
    - **List Literals:** lists consist of any literals seperated by commas and delimited by square brackets. `[1, 2, 3]` or `['David', 'Luckham']`
    - **Time Delta Literals:** `NOW`, or an integral number of days, hours, minutes, or seconds ago.  `2 DAYS AGO` or `10 SECONDS AGO`


- **Value Expressions:** value expressions look similar to matching expressions, but are used to compare the subject event to other events in the stream.  An example expression would look like `(MAX time WHERE type IS 'LoginAttemptFailed')`. Value expressions are always surrounded by `()` and consist of the following parts in order.
    - **Reductive Operator:** reductive operators are optional, and reduce the list of selected values to a single value.  Available operators are `MAX`, `MIN`, `COUNT`, `SUM`, and `UNION`.
    - **Column Name:** specifies the column of the selected events which values should be taken from
    - **Subset Operator:** the subset operator is optional, and allows the expression to select only a subset of the events matching its conditions.  Available subset operators are `FIRST BY column`, `FIRST n BY column`, `LAST BY column`, and `LAST n BY column`.
    - **Conditions:** the value expression is concluded with the `WHERE` keyword, and a set of conditions which may themselves use value expressions and more conditions.  Within a value expression, event column names prefixed with the `^` charachter refer to values on events one level up from the current expression.  Multiple `^` charachters can be chained to break out of multiple nested value expressions.


#### Comparison Operators

The available comparison operators are:

- `=` / `IS` true if the value on the left side is equal to the value on the right.
- `!=` / `IS NOT` true if the value on theleft side is not equal to the value on the right.
- `>=` true if the value on the left is greater than the value on the right side.
- `<=` true if the value on the left is less than or equal to the value on the right side.
- `>` true if the value on the left is greater than than the value on the right.
- `<` true if the value on the left is less than the value on the right.
- `=~` accepts a string on the left and a regular expression on the right, true if the string matches the regex.
- `INCLUDES` accepts a list on the left and a value on the right, true if the value is a member of the list.
- `DOES NOT INCLUDE` accepts a list on the left and a value on the right, true if the value is not a member of the list.
- `IN` accepts a value on the left and a list on the right, true if the value is a member of the list.
- `NOT IN` accepts a value on the left and a list on the right, true if the value is not a member of the list.
- `INTERSECTS` accepts lists on both the left and right sides, true if any value is a member of both lists.
- `DISJOINT` accepts lists on both the left and right sides, true if no value is a member of both lists.



### Type Conditions

Type conditions are aware of the event taxonomy we define and allow us to select facts of a certain type without listing the names of all subtypes.  They consist of the `TYPE` keyword and a string literal naming the type.

The following example uses a type condition to select each event with type 'OrderEvent':

    MATCH EACH AS event WHERE TYPE 'OrderEvent'


---

Blocks
---------

A PQL block consists of any number of matching expressions seperated by semicolons.

    MATCH EACH AS item WHERE type IS 'OrderItemSelected';
    MATCH EACH AS discount WHERE type IS 'OrderLevelDiscountApplied';


### Matching and Cardinality

Blocks match a stream ONLY if all of their constituent matching expressions successfully match the stream at least one time.  A block's matches are the cartesian product of the matches from each individual expression.  This gives the block a cardinality equal to the product of the cardinality of each of its constituent matching expressions.

For example, If the preceding block was applied to following stream, each expression would match 2 times for a cardinality of 2, and the block would match four times for a cardinality of four.

    {id: 1, type: 'OrderItemSelected'},
    {id: 2, type: 'OrderItemSelected'},
    {id: 3, type: 'OrderLevelDiscountApplied'},
    {id: 4, type: 'OrderLevelDiscountApplied'}

The matches here would be the sets of events w/ ids (1, 3), (1, 4), (2, 3), and (2, 4).



---

Rules
-----

Rules define a pattern using a block of PQL, and then accept a block of ruby code to run for each successful match.  The block is run in a context with methods defined for each of the pattern's named matches.  Methods can also be defined for the rule, and run in same context as the action. 

The action block is passed one argument, 'e', an `Entry` instance.  The entry has methods defined to write each fact type in the taxonomy.

```ruby
class PerItemDiscountAccountingRule < Rule

    description 'allocate order level discounts across individual items'

    pattern <<-PQL
      MATCH EACH AS item WHERE type IS 'OrderItemSelected';
      MATCH EACH AS discount WHERE type IS 'OrderLevelDiscountApplied';
    PQL

    method :amount do
      discount.percent * item.amount
    end

    action do |e|
      e.order_level_discount_applied_to_item(
        sku: item.sku,
        promotion_id: discount.promotion_id,
        amount: amount
      )
    end
end
```

---

Events
------

Each event will have a set of types, a set of causes, and any number of other arbitrary attributes.  

The *taxonomy* of event types can be thought of as a directed graph, where each type is a node having edges directed from itself to any number of parent types.

An event's set of types consists of all nodes reachable from its type node.

```ruby
Event::Taxonomy.define do
  type :A, [:B, :C]
  type :D, [:A]
end
```

 In this example, an event of type 'A' will belong to the types 'A', 'B', and 'C', and an event of type 'Z' will belong to the types 'Z', 'A', 'B', and 'C'.

