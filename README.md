
PQL
===

*Pattern Query Language*

A small declarative language for describing patterns in streams of events.


---


An introduction to events and streams
-------------------------------------

Before describing the PQL language, it is important to understand the concepts of events and streams.  

Events are immutable records of things that occur in the world or in our application.  Instead of storing the current state of objects in a problem domain, we can use events to store their entire history.  From the history, we can recreate their state at any point in time and can audit the state changes that brought them there.

In terms of code, events can be thought of as hashes w/ a unique id, type, set of causes, and any number of other named attributes.

Streams are ordered sets of events.  Streams can be created including events related to a specific object, occurring during certain window of time, or at a certain location.


---


Matching Statements
-------------------

    MATCH ALL AS pageviews WHERE TYPE 'PageViewed'

The PQL language consists of *blocks* of *matching statements*.  Matching statements describe specific patterns of events in a stream and Blocks combine multiple matching statements to describe more complex patterns.  

When applied to a stream, matching statements produce a set of *matches*, each consisting of zero or more events.  A statement is said to succeed in matching a stream if its set of matches has at least one member, and fail if its set of matches is empty.


The structure of a matching statement is:

- match keyword: `MATCH`
- selective expression: `ALL`
- naming expression: `AS pageviews`
- filtering expression: `WHERE TYPE 'PageViewed'`



### Match Keyword

Matching statements always begin with the word `MATCH`.



### Selective Expression

Matching statements might find multiple matches in a single stream of events - a statement's *cardinality* with respect to a stream is the number of distinct sets of events matching its pattern that exist in the stream.

Selective expressions describe how a matching statement will distribute filtered events into one or more matches.  In our example, `ALL` (the most basic selective expression) produces a single match, selecting all of the filtered events and giving the expression a cardinality of one.  In contrast, the selective expression `EACH` produces one match for each event in stream meeting the matching statements conditions, for a cardinality equal to the number of filtered events.

Selective expressions can be composed of various subexpressions, interpreted from right to left. Each subexpression applies to the matches produced by the preceding one. 

For example, if we had a stream of events related to final exam scores and wanted to find the highest score in each course, we could use the following matching expression:

    MATCH FIRST IN ORDER BY score GROUPED BY course AS highest WHERE TYPE 'ExamGraded'

This selective expression here is `FIRST IN ORDER BY score GROUPED BY course`, and  its subexpressions are `FIRST`, `IN ORDER BY score`, and  `GROUPED BY course`. 

The rightmost subexpression, `GROUPED BY course` is applied first to split the events into matches by their course attribute.  `IN ORDER BY score` is applied next to sort the events within each match by their score.  Finally, `FIRST` is applied to select only the first event within each match. 


There are three types of selective subexpressions:

  - **Ordering Expressions:** ordering expressions reorder events within each match without changing the number of matches or the number of events in each match.
  
    - `IN ASCENDING ORDER BY column` sorts events within each match from lowest to highest using their value on the named column.
    - `IN ORDER BY column` assumes the order to be ascending and also sorts events from lowest to highest.
    - `IN DESCENDING ORDER BY column` sorts events within each match from highest to lowest.

  - **Limiting Expressions:** limiting expressions select subsets of events within each match without changing the overall number of matches.
    
    - `FIRST` / `FIRST n` select events from the beginning of the stream
    - `LAST` / `LAST n` select events from the end of the stream

  - **Cardinality Expressions:** cardinality expressions determine the number of matches.

    - `ALL` is the default cardinality - it matches one time selecting all of the events meeting the conditions.
    - `EACH` matches once for each event in the stream, selecting one event in each match.
    - `ANY` always matches one time, whether or not any events in the stream meet the conditions.  If any events do meet the conditions, it selects them, otherwise it selects no events.
    - `NONE` matches one time and selects no events.  It matches only if no events in the stream meet the conditions.
    - `GROUPED BY column` matches once for each unique value of a column, selecting the set of events sharing that value.



### Naming Expression

Matches can be optionally named by including a naming expression immediately following the selective expression.  In the first example, `MATCH ALL AS pageviews WHERE TYPE 'PageViewed'`, the naming expression `AS pageviews` names the match 'pageviews'.  

A naming expression consists of the `AS` keyword followed by a match name.  Match names are not quoted and can contain upper and lower case letters and underscores.



### Filtering Expressions

Filtering expressions are made up of a set of conditions and begin with the `WHERE` keyword.  Conditions are ordered using `()` and combined using the boolean operators `AND` and `OR`.  To find matching events, an expression checks each fact in the stream individually against its conditions - selecting the events for which the conditions are true.



### Comparisons

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


- **Value Expressions:** value expressions look similar to filter expressions, but are used to compare the subject event to other events in the stream.  An example expression would look like `(MAX time WHERE status = 'error')`. Value expressions are always surrounded by `()` and consist of the following parts in order.
    - **Reductive Operator:** reductive operators are optional, and reduce the list of selected values to a single value.  Available operators are `MAX`, `MIN`, `COUNT`, `SUM`, and `UNION`.
    - **Column Name:** specifies the column of the selected events which values should be taken from
    - **Subset Expression:** the subset expression is optional, and allows a value expression to select only a subset of the events matching its conditions.  Subset expressions are similar to selective expressions, but are made up only of ordering and limiting subexpressions and can not include cardinality expressions.  `FIRST`, `FIRST n`, and `LAST n IN ORDER BY column` are examples of valid subset expressions.
    - **Conditions:** the value expression is concluded with the `WHERE` keyword, and a set of conditions which may themselves use value expressions and more conditions.  Within a value expression, event column names prefixed with `^`, the  escape operator, refer to values on events one level up from the current expression.  Multiple escapes can be chained to break out of multiple nested value expressions.  Escapes force the result of a value expression to be recalculated for each event in the stream, and should consequentially be used carefully.


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

Type conditions are aware of the event ontology we define and allow us to select all events of a certain type without listing the names of all subtypes.  They consist of the `TYPE` keyword and a string literal naming the type.

The following example uses a type condition to select each event with type 'OrderEvent':

    MATCH EACH AS event WHERE TYPE 'OrderEvent'


---


Blocks
------

A PQL block consists of any number of matching statements seperated by semicolons.

    MATCH EACH AS item WHERE TYPE 'OrderItemSelected';
    MATCH EACH AS discount WHERE TYPE 'OrderLevelDiscountApplied';



### Matching and Cardinality

Blocks match a stream ONLY if all of their constituent matching statements successfully match the stream at least one time.  A block's matches are the cartesian product of the matches from each individual statement.  This gives the block a cardinality equal to the product of the cardinality of each of its constituent matching statements.

For example, If the preceding block was applied to following stream, each statement would match 2 times for a cardinality of 2, and the block would match four times for a cardinality of four.

```ruby
{id: 1, type: 'ItemAddedToCart'},
{id: 2, type: 'ItemAddedToCart'},
{id: 3, type: 'OrderLevelDiscountApplied'},
{id: 4, type: 'OrderLevelDiscountApplied'}
```

The matches would be the sets of events w/ ids (1, 3), (1, 4), (2, 3), and (2, 4).



### Joining Expressions

In blocks, joining expressions can be used to associate new matches with sepecific matches produced by a preceding  statement.  For example, the following expression will match two times, associating each matched `ItemLevelDiscountApplied` event with a specific `ItemAddedToCart` event.

    MATCH EACH AS item WHERE TYPE 'ItemAddedToCart';
    MATCH EACH AS discount WHERE TYPE 'ItemLevelDiscountApplied' JOINING item WHERE applied_to = item.id;

Joining expressions end matching statements and consisit of the `JOINING` keyword, the name of a preceding match, and a filtering expression.  Within the filtering expression, columns on the named match are referenced using dot notation, in this case `item.id`.

Matching statements with joins that successfuly match a stream have no effect on the cardinality of a block.  Statements that fail to match have a cardinality of zero.

When applied to the following stream, the preceding block will match only two times, selecting the sets of events with ids (1,3) and (2,4).

```ruby
{id: 1, type: 'ItemAddedToCart'},
{id: 2, type: 'ItemAddedToCart'},
{id: 3, type: 'ItemLevelDiscountApplied', applied_to: 1},
{id: 4, type: 'ItemLevelDiscountApplied', applied_to: 2}
```
