creole = require './creole'
oldParser = new (require './creole.old').Parser

class TestBuilder
  constructor: ->
    @context = []
    @result = []
  e: (value) ->
    value = value.trim()
    @result.push 'e: ' + value unless value == ''
  u: (value) ->
    value = value.trim()
    @result.push 'u: ' + value unless value == ''
  bold:
    start: -> @u '<strong>'
    end: -> @u '</strong>'
  italics:
    start: -> @u '<em>'
    end: -> @u '</em>'
  heading1:
    start: -> @u '<h1>'
    end: -> @u '</h1>'
  heading2:
    start: -> @u '<h2>'
    end: -> @u '</h2>'
  heading3:
    start: -> @u '<h3>'
    end: -> @u '</h3>'
  heading4:
    start: -> @u '<h4>'
    end: -> @u '</h4>'
  heading5:
    start: -> @u '<h5>'
    end: -> @u '</h5>'
  heading6:
    start: -> @u '<h6>'
    end: -> @u '</h6>'
  link:
    start: (options) ->
      @u '<a type="'
      @e options.type
      @u '" href="'
      @e options.link
      @u '">'
    end: -> @u '</a>'
  url:
    start: (options) ->
      @u '<a href="'
      @e options.link
      @u '">'
      @e options.link
    end: -> @u '</a>'
  paragraph:
    start: -> @u '<p>'
    end: -> @u '</p>'
  lineBreak:
    start: -> @u '<br />'
    end: ->
  unorderedList:
    start: -> @u '<ul>'
    end: -> @u '</ul>'
  orderedList:
    start: -> @u '<ol>'
    end: -> @u '</ol>'
  listItem:
    start: -> @u '<li>'
    end: -> @u '</li>'
  horizontalRule:
    start: -> @u '<hr />'
    end: ->
  image:
    start: (options) ->
      @u '<img type="'
      @e options.type
      @u '" src="'
      @e options.link
      @u '" title="'
      @e options.title
      @u '" />'
    end: ->
  table:
    start: -> @u '<table>'
    end: -> @u '</table>'
  tableRow:
    start: -> @u '<tr>'
    end: -> @u '</tr>'
  tableHeading:
    start: -> @u '<th>'
    end: -> @u '</th>'
  tableCell:
    start: -> @u '<td>'
    end: -> @u '</td>'
  nowiki:
    start: -> @u '<pre>'
    end: -> @u '</pre>'
  inlineNowiki:
    start: -> @u '<tt>'
    end: -> @u '</tt>'
  escaped:
    start: -> @u '<escaped>'
    end: -> @u '</escaped>'
  start: (name, options) ->
    handler = @[name]
    if handler?
      @context.push handler
      handler.start.call @, options
    else
      @context.push null
  end: ->
    @context.pop()?.end.call @
  text: (value) -> @e value

describe 'Creole 1.0', ->
  builder = null
  beforeEach -> builder = new TestBuilder
  it 'should parse Bold', ->
    creole.parse builder, '''
    **bold**
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    u: <strong>
    e: bold
    u: </strong>
    u: </p>
    '''
  it 'should parse Italics', ->
    creole.parse builder, '''
    //italics//
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    u: <em>
    e: italics
    u: </em>
    u: </p>
    '''
  it 'should be able to cross lines', ->
    creole.parse builder, '''
    Bold and italics should //be
    able// to cross lines.

    But, should //not be...

    ...able// to cross paragraphs.
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    e: Bold and italics should
    u: <em>
    e: be
    able
    u: </em>
    e: to cross lines.
    u: </p>
    u: <p>
    e: But, should
    u: <em>
    e: not be...
    u: </em>
    u: </p>
    u: <p>
    e: ...able
    u: <em>
    e: to cross paragraphs.
    u: </em>
    u: </p>
    '''
  it 'should parse Bold Italics', ->
    creole.parse builder, '''
    **//bold italics//**
    //**bold italics**//
    //This is **also** good.//
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    u: <strong>
    u: <em>
    e: bold italics
    u: </em>
    u: </strong>
    u: <em>
    u: <strong>
    e: bold italics
    u: </strong>
    u: </em>
    u: <em>
    e: This is
    u: <strong>
    e: also
    u: </strong>
    e: good.
    u: </em>
    u: </p>
    '''
  it 'should parse Headings', ->
    creole.parse builder, '''
    = Level 1 (largest) =
    == Level 2 ==
    === Level 3 ===
    ==== Level 4 ====
    ===== Level 5 =====
    ====== Level 6 ======
    === Also level 3
    === Also level 3 =
    === Also level 3 ==
    === **not** //parsed// ===
    '''
    builder.result.join('\n').should.equal '''
    u: <h1>
    e: Level 1 (largest)
    u: </h1>
    u: <h2>
    e: Level 2
    u: </h2>
    u: <h3>
    e: Level 3
    u: </h3>
    u: <h4>
    e: Level 4
    u: </h4>
    u: <h5>
    e: Level 5
    u: </h5>
    u: <h6>
    e: Level 6
    u: </h6>
    u: <h3>
    e: Also level 3
    u: </h3>
    u: <h3>
    e: Also level 3
    u: </h3>
    u: <h3>
    e: Also level 3
    u: </h3>
    u: <h3>
    e: **not** //parsed//
    u: </h3>
    '''
  it 'should parse Links', ->
    creole.parse builder, '''
    [[link]]
    [[MyBigPage|Go to my page]]
    [[http://www.wikicreole.org/]]
    http://www.rawlink.org/, http://www.another.rawlink.org
    [[http://www.wikicreole.org/|Visit the WikiCreole website]]
    [[Weird Stuff|**Weird** //Stuff//]]
    [[Ohana:WikiFamily]]
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    u: <a type="
    e: internal
    u: " href="
    e: link
    u: ">
    e: link
    u: </a>
    u: <a type="
    e: internal
    u: " href="
    e: MyBigPage
    u: ">
    e: Go to my page
    u: </a>
    u: <a type="
    e: external
    u: " href="
    e: http://www.wikicreole.org/
    u: ">
    e: http://www.wikicreole.org/
    u: </a>
    u: <a href="
    e: http://www.rawlink.org/
    u: ">
    e: http://www.rawlink.org/
    u: </a>
    e: ,
    u: <a href="
    e: http://www.another.rawlink.org
    u: ">
    e: http://www.another.rawlink.org
    u: </a>
    u: <a type="
    e: external
    u: " href="
    e: http://www.wikicreole.org/
    u: ">
    e: Visit the WikiCreole website
    u: </a>
    u: <a type="
    e: internal
    u: " href="
    e: Weird Stuff
    u: ">
    u: <strong>
    e: Weird
    u: </strong>
    u: <em>
    e: Stuff
    u: </em>
    u: </a>
    u: <a type="
    e: interwiki
    u: " href="
    e: Ohana:WikiFamily
    u: ">
    e: Ohana:WikiFamily
    u: </a>
    u: </p>
    '''
  it 'should parse Paragraphs', ->
    creole.parse builder, '''
    This is my text.

    This is more text.
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    e: This is my text.
    u: </p>
    u: <p>
    e: This is more text.
    u: </p>
    '''
  it 'should parse Line Breaks', ->
    creole.parse builder, '''
    This is the first line,\\\\and this is the second.
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    e: This is the first line,
    u: <br />
    e: and this is the second.
    u: </p>
    '''
  it 'should parse Unordered Lists', ->
    creole.parse builder, '''
    * Item 1
    ** Item 1.1
    * Item 2
    '''
    builder.result.join('\n').should.equal '''
    u: <ul>
    u: <li>
    e: Item 1
    u: <ul>
    u: <li>
    e: Item 1.1
    u: </li>
    u: </ul>
    u: </li>
    u: <li>
    e: Item 2
    u: </li>
    u: </ul>
    '''
  it 'should parse Ordered Lists', ->
    creole.parse builder, '''
    # Item 1
    ## Item 1.1
    # Item 2
    '''
    builder.result.join('\n').should.equal '''
    u: <ol>
    u: <li>
    e: Item 1
    u: <ol>
    u: <li>
    e: Item 1.1
    u: </li>
    u: </ol>
    u: </li>
    u: <li>
    e: Item 2
    u: </li>
    u: </ol>
    '''
  it 'should parse Horizontal Rule', ->
    creole.parse builder, '''
    ----
    '''
    builder.result.join('\n').should.equal '''
    u: <hr />
    '''
  it 'should parse Image', ->
    creole.parse builder, '''
    {{myimage.png|this is my image}}
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    u: <img type="
    e: internal
    u: " src="
    e: myimage.png
    u: " title="
    e: this is my image
    u: " />
    u: </p>
    '''
  it 'should parse Tables', ->
    creole.parse builder, '''
    |=Heading Col 1 |=Heading Col 2         |
    |Cell 1.1       |Two lines\\\\in Cell 1.2 |
    |Cell 2.1       |Cell 2.2               |
    '''
    builder.result.join('\n').should.equal '''
    u: <table>
    u: <tr>
    u: <th>
    e: Heading Col 1
    u: </th>
    u: <th>
    e: Heading Col 2
    u: </th>
    u: </tr>
    u: <tr>
    u: <td>
    e: Cell 1.1
    u: </td>
    u: <td>
    e: Two lines
    u: <br />
    e: in Cell 1.2
    u: </td>
    u: </tr>
    u: <tr>
    u: <td>
    e: Cell 2.1
    u: </td>
    u: <td>
    e: Cell 2.2
    u: </td>
    u: </tr>
    u: </table>
    '''
  it 'should parse Nowiki', ->
    creole.parse builder, '''
    {{{
    //This// does **not** get [[formatted]]
    }}}
    '''
    builder.result.join('\n').should.equal '''
    u: <pre>
    e: //This// does **not** get [[formatted]]
    u: </pre>
    '''
  it 'should parse Inline Nowiki', ->
    creole.parse builder, '''
    Some examples of markup are: {{{** <i>this</i> ** }}}
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    e: Some examples of markup are:
    u: <tt>
    e: ** <i>this</i> **
    u: </tt>
    u: </p>
    '''
  it 'should parse Inline Nowiki with closing braces', ->
    creole.parse builder, '''
    {{{{{if (a>b) { b = a; }}}}}}
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    u: <tt>
    e: {{if (a>b) { b = a; }}}
    u: </tt>
    u: </p>
    '''
  it 'should parse Nowiki with a line containing three closing braces', ->
    creole.parse builder, '''
    {{{
    if (x != NULL) {
      for (i = 0; i < size; i++) {
        if (x[i] . 0) {
          x[i]--;
      }}}
    }}}
    '''
    builder.result.join('\n').should.equal '''
    u: <pre>
    e: if (x != NULL) {
      for (i = 0; i < size; i++) {
        if (x[i] . 0) {
          x[i]--;
     }}}
    u: </pre>
    '''
  it 'should parse Escape Character', ->
    creole.parse builder, '''
    ~#1
    http://www.foo.com/~bar/
    ~http://www.foo.com/
    CamelCaseLink
    ~CamelCaseLink
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    u: <escaped>
    e: #
    u: </escaped>
    e: 1
    u: <a href="
    e: http://www.foo.com/~bar/
    u: ">
    e: http://www.foo.com/~bar/
    u: </a>
    u: <escaped>
    e: http://www.foo.com/
    u: </escaped>
    e: CamelCaseLink
    u: <escaped>
    e: C
    u: </escaped>
    e: amelCaseLink
    u: </p>
    '''
  it 'should parse Bold and/or italic links', ->
    creole.parse builder, '''
    //[[Important page|this link is italicized]]//
    **[[Important page]]**
    //**[[Important page]]**//
    '''
    builder.result.join('\n').should.equal '''
    u: <p>
    u: <em>
    u: <a type="
    e: internal
    u: " href="
    e: Important page
    u: ">
    e: this link is italicized
    u: </a>
    u: </em>
    u: <strong>
    u: <a type="
    e: internal
    u: " href="
    e: Important page
    u: ">
    e: Important page
    u: </a>
    u: </strong>
    u: <em>
    u: <strong>
    u: <a type="
    e: internal
    u: " href="
    e: Important page
    u: ">
    e: Important page
    u: </a>
    u: </strong>
    u: </em>
    u: </p>
    '''
  it 'should parse Bold, Italics, Links, Nowiki in Lists', ->
    creole.parse builder, '''
    * **bold** item
    * //italic// item
    # item about a [[certain page]]
    # {{{ //this// is **not** [[processed]] }}}
    '''
    builder.result.join('\n').should.equal '''
    u: <ul>
    u: <li>
    u: <strong>
    e: bold
    u: </strong>
    e: item
    u: </li>
    u: <li>
    u: <em>
    e: italic
    u: </em>
    e: item
    u: </li>
    u: </ul>
    u: <ol>
    u: <li>
    e: item about a
    u: <a type="
    e: internal
    u: " href="
    e: certain page
    u: ">
    e: certain page
    u: </a>
    u: </li>
    u: <li>
    u: <tt>
    e: //this// is **not** [[processed]]
    u: </tt>
    u: </li>
    u: </ol>
    '''

describe 'Creole 1.0 Test Cases', ->
  source = '''
= Top-level heading (1)
== This a test for creole 0.1 (2)
=== This is a Subheading (3)
==== Subsub (4)
===== Subsubsub (5)

The ending equal signs should not be displayed:

= Top-level heading (1) =
== This a test for creole 0.1 (2) ==
=== This is a Subheading (3) ===
==== Subsub (4) ====
===== Subsubsub (5) =====


You can make things **bold** or //italic// or **//both//** or //**both**//.

Character formatting extends across line breaks: **bold,
this is still bold. This line deliberately does not end in star-star.

Not bold. Character formatting does not cross paragraph boundaries.

You can use [[internal links]] or [[http://www.wikicreole.org|external links]],
give the link a [[internal links|different]] name.

Here's another sentence: This wisdom is taken from [[Ward Cunningham's]]
[[http://www.c2.com/doc/wikisym/WikiSym2006.pdf|Presentation at the Wikisym 06]].

Here's a external link without a description: [[http://www.wikicreole.org]]

Be careful that italic links are rendered properly:  //[[http://my.book.example/|My Book Title]]// 

Free links without braces should be rendered as well, like http://www.wikicreole.org/ and http://www.wikicreole.org/users/~example. 

Creole1.0 specifies that http://bar and ftp://bar should not render italic,
something like foo://bar should render as italic.

You can use this to draw a line to separate the page:
----

You can use lists, start it at the first column for now, please...

unnumbered lists are like
* item a
* item b
* **bold item c**

blank space is also permitted before lists like:
  *   item a
 * item b
* item c
 ** item c.a

or you can number them
# [[item 1]]
# item 2
# // italic item 3 //
    ## item 3.1
  ## item 3.2

up to five levels
* 1
** 2
*** 3
**** 4
***** 5

* You can have
multiline list items
* this is a second multiline
list item

You can use nowiki syntax if you would like do stuff like this:

{{{
Guitar Chord C:

||---|---|---|
||-0-|---|---|
||---|---|---|
||---|-0-|---|
||---|---|-0-|
||---|---|---|
}}}

You can also use it inline nowiki {{{ in a sentence }}} like this.

= Escapes =
Normal Link: http://wikicreole.org/ - now same link, but escaped: ~http://wikicreole.org/ 

Normal asterisks: ~**not bold~**

a tilde alone: ~

a tilde escapes itself: ~~xxx

=== Creole 0.2 ===

This should be a flower with the ALT text "this is a flower" if your wiki supports ALT text on images:

{{Red-Flower.jpg|here is a red flower}}

=== Creole 0.4 ===

Tables are done like this:

|=header col1|=header col2| 
|col1|col2| 
|you         |can         | 
|also        |align\\\\ it. | 

You can format an address by simply forcing linebreaks:

My contact dates:\\\\
Pone: xyz\\\\
Fax: +45\\\\
Mobile: abc

=== Creole 0.5 ===

|= Header title               |= Another header title     |
| {{{ //not italic text// }}} | {{{ **not bold text** }}} |
| //italic text//             | **  bold text **          |

=== Creole 1.0 ===

If interwiki links are setup in your wiki, this links to the WikiCreole page about Creole 1.0 test cases: [[WikiCreole:Creole1.0TestCases]].
  '''
  it 'should parse as expected', ->
    builder = new TestBuilder
    creole.parse builder, source
    builder.result.join('\n').should.equal '''
u: <h1>
e: Top-level heading (1)
u: </h1>
u: <h2>
e: This a test for creole 0.1 (2)
u: </h2>
u: <h3>
e: This is a Subheading (3)
u: </h3>
u: <h4>
e: Subsub (4)
u: </h4>
u: <h5>
e: Subsubsub (5)
u: </h5>
u: <p>
e: The ending equal signs should not be displayed:
u: </p>
u: <h1>
e: Top-level heading (1)
u: </h1>
u: <h2>
e: This a test for creole 0.1 (2)
u: </h2>
u: <h3>
e: This is a Subheading (3)
u: </h3>
u: <h4>
e: Subsub (4)
u: </h4>
u: <h5>
e: Subsubsub (5)
u: </h5>
u: <p>
e: You can make things
u: <strong>
e: bold
u: </strong>
e: or
u: <em>
e: italic
u: </em>
e: or
u: <strong>
u: <em>
e: both
u: </em>
u: </strong>
e: or
u: <em>
u: <strong>
e: both
u: </strong>
u: </em>
e: .
u: </p>
u: <p>
e: Character formatting extends across line breaks:
u: <strong>
e: bold,
this is still bold. This line deliberately does not end in star-star.
u: </strong>
u: </p>
u: <p>
e: Not bold. Character formatting does not cross paragraph boundaries.
u: </p>
u: <p>
e: You can use
u: <a type="
e: internal
u: " href="
e: internal links
u: ">
e: internal links
u: </a>
e: or
u: <a type="
e: external
u: " href="
e: http://www.wikicreole.org
u: ">
e: external links
u: </a>
e: ,
give the link a
u: <a type="
e: internal
u: " href="
e: internal links
u: ">
e: different
u: </a>
e: name.
u: </p>
u: <p>
e: Here's another sentence: This wisdom is taken from
u: <a type="
e: internal
u: " href="
e: Ward Cunningham's
u: ">
e: Ward Cunningham's
u: </a>
u: <a type="
e: external
u: " href="
e: http://www.c2.com/doc/wikisym/WikiSym2006.pdf
u: ">
e: Presentation at the Wikisym 06
u: </a>
e: .
u: </p>
u: <p>
e: Here's a external link without a description:
u: <a type="
e: external
u: " href="
e: http://www.wikicreole.org
u: ">
e: http://www.wikicreole.org
u: </a>
u: </p>
u: <p>
e: Be careful that italic links are rendered properly:
u: <em>
u: <a type="
e: external
u: " href="
e: http://my.book.example/
u: ">
e: My Book Title
u: </a>
u: </em>
u: </p>
u: <p>
e: Free links without braces should be rendered as well, like
u: <a href="
e: http://www.wikicreole.org/
u: ">
e: http://www.wikicreole.org/
u: </a>
e: and
u: <a href="
e: http://www.wikicreole.org/users/~example
u: ">
e: http://www.wikicreole.org/users/~example
u: </a>
e: .
u: </p>
u: <p>
e: Creole1.0 specifies that
u: <a href="
e: http://bar
u: ">
e: http://bar
u: </a>
e: and
u: <a href="
e: ftp://bar
u: ">
e: ftp://bar
u: </a>
e: should not render italic,
something like foo:
u: <em>
e: bar should render as italic.
u: </em>
u: </p>
u: <p>
e: You can use this to draw a line to separate the page:
u: </p>
u: <hr />
u: <p>
e: You can use lists, start it at the first column for now, please...
u: </p>
u: <p>
e: unnumbered lists are like
u: </p>
u: <ul>
u: <li>
e: item a
u: </li>
u: <li>
e: item b
u: </li>
u: <li>
u: <strong>
e: bold item c
u: </strong>
u: </li>
u: </ul>
u: <p>
e: blank space is also permitted before lists like:
u: </p>
u: <ul>
u: <li>
e: item a
u: </li>
u: <li>
e: item b
u: </li>
u: <li>
e: item c
u: <ul>
u: <li>
e: item c.a
u: </li>
u: </ul>
u: </li>
u: </ul>
u: <p>
e: or you can number them
u: </p>
u: <ol>
u: <li>
u: <a type="
e: internal
u: " href="
e: item 1
u: ">
e: item 1
u: </a>
u: </li>
u: <li>
e: item 2
u: </li>
u: <li>
u: <em>
e: italic item 3
u: </em>
u: <ol>
u: <li>
e: item 3.1
u: </li>
u: <li>
e: item 3.2
u: </li>
u: </ol>
u: </li>
u: </ol>
u: <p>
e: up to five levels
u: </p>
u: <ul>
u: <li>
e: 1
u: <ul>
u: <li>
e: 2
u: <ul>
u: <li>
e: 3
u: <ul>
u: <li>
e: 4
u: <ul>
u: <li>
e: 5
u: </li>
u: </ul>
u: </li>
u: </ul>
u: </li>
u: </ul>
u: </li>
u: </ul>
u: </li>
u: </ul>
u: <ul>
u: <li>
e: You can have
multiline list items
u: </li>
u: <li>
e: this is a second multiline
list item
u: </li>
u: </ul>
u: <p>
e: You can use nowiki syntax if you would like do stuff like this:
u: </p>
u: <pre>
e: Guitar Chord C:

||---|---|---|
||-0-|---|---|
||---|---|---|
||---|-0-|---|
||---|---|-0-|
||---|---|---|
u: </pre>
u: <p>
e: You can also use it inline nowiki
u: <tt>
e: in a sentence
u: </tt>
e: like this.
u: </p>
u: <h1>
e: Escapes
u: </h1>
u: <p>
e: Normal Link:
u: <a href="
e: http://wikicreole.org/
u: ">
e: http://wikicreole.org/
u: </a>
e: - now same link, but escaped:
u: <escaped>
e: http://wikicreole.org/
u: </escaped>
u: </p>
u: <p>
e: Normal asterisks:
u: <escaped>
e: *
u: </escaped>
e: *not bold
u: <escaped>
e: *
u: </escaped>
e: *
u: </p>
u: <p>
e: a tilde alone: ~
u: </p>
u: <p>
e: a tilde escapes itself:
u: <escaped>
e: ~
u: </escaped>
e: xxx
u: </p>
u: <h3>
e: Creole 0.2
u: </h3>
u: <p>
e: This should be a flower with the ALT text "this is a flower" if your wiki supports ALT text on images:
u: </p>
u: <p>
u: <img type="
e: internal
u: " src="
e: Red-Flower.jpg
u: " title="
e: here is a red flower
u: " />
u: </p>
u: <h3>
e: Creole 0.4
u: </h3>
u: <p>
e: Tables are done like this:
u: </p>
u: <table>
u: <tr>
u: <th>
e: header col1
u: </th>
u: <th>
e: header col2
u: </th>
u: </tr>
u: <tr>
u: <td>
e: col1
u: </td>
u: <td>
e: col2
u: </td>
u: </tr>
u: <tr>
u: <td>
e: you
u: </td>
u: <td>
e: can
u: </td>
u: </tr>
u: <tr>
u: <td>
e: also
u: </td>
u: <td>
e: align
u: <br />
e: it.
u: </td>
u: </tr>
u: </table>
u: <p>
e: You can format an address by simply forcing linebreaks:
u: </p>
u: <p>
e: My contact dates:
u: <br />
e: Pone: xyz
u: <br />
e: Fax: +45
u: <br />
e: Mobile: abc
u: </p>
u: <h3>
e: Creole 0.5
u: </h3>
u: <table>
u: <tr>
u: <th>
e: Header title
u: </th>
u: <th>
e: Another header title
u: </th>
u: </tr>
u: <tr>
u: <td>
u: <tt>
e: //not italic text//
u: </tt>
u: </td>
u: <td>
u: <tt>
e: **not bold text**
u: </tt>
u: </td>
u: </tr>
u: <tr>
u: <td>
u: <em>
e: italic text
u: </em>
u: </td>
u: <td>
u: <strong>
e: bold text
u: </strong>
u: </td>
u: </tr>
u: </table>
u: <h3>
e: Creole 1.0
u: </h3>
u: <p>
e: If interwiki links are setup in your wiki, this links to the WikiCreole page about Creole 1.0 test cases:
u: <a type="
e: interwiki
u: " href="
e: WikiCreole:Creole1.0TestCases
u: ">
e: WikiCreole:Creole1.0TestCases
u: </a>
e: .
u: </p>
    '''
  it 'old parser should parse asis', ->
    oldParser.parse new TestBuilder, source for i in [0...1000]
  it 'should parse faster', ->
    creole.parse new TestBuilder, source for i in [0...1000]
