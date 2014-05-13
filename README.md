PQL
===

*Pattern Query Language*

A small declarative language for describing patterns in a stream of events.

---

Matching Expressions
--------------------------------

Matching expressions match the presence or absence of a specific set of
facts in a stream.  

    MATCH ALL AS pageviews WHERE type IS 'PageViewed'

A matching expression can be broken down into the following parts:

- match keyword: `MATCH`
- cardinality operator: `ALL`
- naming expression: `AS pageviews`
- conditions: `WHERE type IS 'PageViewed'` 


### Match Keyword

matching expressions always begin with the word `MATCH`


### Cardinality Operator

Matching expressions can match the same stream of events multiple times - an expression's *cardinality* with respect to a stream is the number of distinct sets of events it matches in the stream.

In the given example `ALL` will match once, selecting the all events all of the events with type 'PageViewed' and giving the expression a cardinality of one.

The available cardinality operators are:

  - `ALL` matches one time selecting all of the events meeting the conditions
  - `EACH` matches once for each fact in the stream, selecting one fact w/ each match.
  - `NONE` - matches once and selects no events.  It matches only if no events in the stream meet the given conditions.   
  - `FIRST BY column` matches one time selecting the single event with the smallest value for 'column'
  - `FIRST n BY column` matches one time selecting n events with the smallest values for 'column'
  - `LAST BY column` matches one time selecting the single event with the largest value for 'column'
  - `LAST n BY column` matches one time selecting n events with the largest values for 'column'


### Naming Expression

Matches can be optionally named by including a naming expression immediately following the cardinality operator.  In the preceding example `AS pageviews` names the match 'pageviews'.  

A naming expression consists of the `AS` keyword followed by a match name.  Match names are not quoted and can contain upper and lower case letters and underscores.


### Conditions

The set of conditions for a matching expression begins with the `WHERE` keyword, and is followed by any number of comparisons ordered using `()` and combined using the boolean operators `AND` and `OR`.  To find matching events, an expression checks each fact in the stream individually against its conditions - selecting the events for which the conditions are true.

The most basic condition follows the format `left value` `comparison operator` `right value`

#### Values

Values can be references to the value of a column on the event currently being considered (the *subject event*), literal values, or references to values of other events in the stream (*value expressions*). 

- **Subject Event Columns:** subject event columns refer to values on the subject event.  For example, in the condition `WHERE type IS 'PageViewed'`, `type` is a subject event column and refers to the value of the column named `type` on the subject event.  The condition will be true for subject event `{type: 'PageViewed'}`.  Column names can consist of lower and uppercase letters and underscores.

- **Literals:**  literals express a value directly without reference to the subject event or other  events in the stream.
    - **Integer Literals:** `1`, `12`, or `9001`
    - **Floating Point Literals:** `1.1`, `3.14`, or `99.999`
    - **String Literals:** delimited by single or double quotes. `"Etzion & Niblett"` or `'Oprah Winfrey'`
    - **Regular Expression Literals:** `/^abcd/` or `/[0-9]+/`
    - **List Literals:** lists consist of any literals seperated by commas and delimited by square brackets. `[1, 2, 3]` or `['David', 'Luckham']`

- **Value Expressions:** value expressions look similar to matching expressions, but are used to compare the subject event to other events in the stream.  An example expression would look like `(MAX time WHERE type IS 'LoginAttemptFailed')`. Value expressions are always surrounded by `()` and consist of the following parts in order.
    - **Reductive Operator:** reductive operators are optional, and reduce the list of selected values to a single value.  Available operators are `MAX`, `MIN`, `COUNT`, and `SUM`.
    - **Column Name:** specifies the column of the selected events which values should be taken from 
    - **Subset Operator:** the subset operator is optional, and allows the expression to select only a subset of the events matching its conditions.  Available subset operators are `FIRST BY column`, `FIRST n BY column`, `LAST BY column`, and `LAST n BY column`.
    - **Conditions:** the value expression is concluded with the `WHERE` keyword, and a set of conditions which may themselves use value expressions and more conditions. 

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
-------

Rules define a pattern using a block of PQL, and then accept a block of ruby code to run for each successful match 

```ruby
class PerItemDiscountAccountingRule
    pql <<-PQL
      MATCH EACH AS item WHERE type IS 'OrderItemSelected'; 
      MATCH EACH AS discount WHERE type IS 'OrderLevelDiscountApplied';
    PQL
    
    action do
      order_level_discount_applied_to_item(
        sku: item.sku,
        promotion_id: discount.promotion_id, 
        amount: discount.percent * item.amount
      )
    end
end
```
