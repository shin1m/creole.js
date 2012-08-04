class Rule
  constructor: (params) -> @[key] = value for key, value of params
  match: (data) -> data.match @regex
  build: (builder, r) ->
    builder.start @name, {}
    data = r[@capture] if @capture?
    if data
      data = data.replace @replaceRegex, @replaceString if @replaceRegex?
      @apply builder, data
    builder.end()
  apply: (builder, data) ->
    tail = '' + data
    matches = []
    while true
      best = false
      rule = null
      if @children?
        for child, i in @children
          matches[i] = child.match tail unless matches[i]?
          if matches[i] && (!best || best.index > matches[i].index)
            best = matches[i]
            rule = child
            break if best.index == 0
      pos = if best then best.index else tail.length
      @fallback.apply builder, tail.substring(0, pos) if pos > 0
      break unless best
      rule.build builder, best
      chopped = best.index + best[0].length
      tail = tail.substring chopped
      if @children?
        for child, i in @children
          if matches[i]
            if matches[i].index >= chopped
              matches[i].index -= chopped
            else
              matches[i] = null
  fallback:
    apply: (builder, data) -> builder.text data

class Parser
  constructor: (@options = null) ->
    rx =
      link: '[^\\]|~\\n]*(?:(?:\\](?!\\])|~.)[^\\]|~\\n]*)*'
      linkText: '[^\\]~\\n]*(?:(?:\\](?!\\])|~.)[^\\]~\\n]*)*'
      uriPrefix: '\\b(?:(?:https?|ftp)://|mailto:)'
      interwikiPrefix: '[\\w.]+:'
      image: '\\{\\{((?!\\{)[^|}\\n]*(?:}(?!})[^|}\\n]*)*)' +
        (if @options?.strict then '' else '(?:') +
        '\\|([^}~\\n]*((}(?!})|~.)[^}~\\n]*)*)' +
        (if @options?.strict then '' else ')?') + '}}'
    rx.uri = rx.uriPrefix + rx.link
    rx.rawUri = rx.uriPrefix + '\\S*[^\\s!"\',.:;?]'
    rx.interwikiLink = rx.interwikiPrefix + rx.link
    g = {}
    add = (rule) -> g[rule.name] = rule
    add new Rule
      name: 'bold'
      capture: 1
      regex: /\*\*([^*~]*((\*(?!\*)|~(.|(?=\n)|$))[^*~]*)*)(\*\*|\n|$)/
    add new Rule
      name: 'italics'
      capture: 1
      regex: '\\/\\/(((?!' + rx.uriPrefix + ')[^\\/~])*' +
             '((' + rx.rawUri + '|\\/(?!\\/)|~(.|(?=\\n)|$))' +
               '((?!' + rx.uriPrefix + ')[^\\/~])*)*)(\\/\\/|\\n|$)'
    for i in [1..6]
      add new Rule
        name: 'heading' + i
        capture: 2
        regex: '(^|\\n)[ \\t]*={' + i + '}[ \\t]([^~]*?(~(.|(?=\\n)|$))*)[ \\t]*=*\\s*(\\n|$)'
    add new Rule
      name: 'internalLink'
      regex: '\\[\\[(' + rx.link + ')(\\|(' + rx.linkText + '))?\\]\\]'
      build: (builder, r) ->
        builder.start 'link',
          type: 'internal'
          link: r[1].replace /~(.)/g, '$1'
        @apply builder, r[3] ? r[1]
        builder.end()
    add new Rule
      name: 'externalLink'
      regex: '\\[\\[(' + rx.uri + ')(\\|(' + rx.linkText + '))?\\]\\]'
      build: (builder, r) ->
        builder.start 'link',
          type: 'external'
          link: r[1]
        if r[3]?
          @apply builder, r[3]
        else
          builder.text r[1]
        builder.end()
    add new Rule
      name: 'url'
      regex: '(' + rx.rawUri + ')'
      build: (builder, r) ->
        builder.start @name,
          link: r[1]
        builder.end()
    add new Rule
      name: 'interwikiLink'
      regex: '\\[\\[(' + rx.interwikiLink + ')(\\|(' + rx.linkText + '))?\\]\\]'
      build: (builder, r) ->
        builder.start 'link'
          type: 'interwiki'
          link: r[1].replace /~(.)/g, '$1'
        @apply builder, r[3] ? r[1]
        builder.end()
    add new Rule
      name: 'paragraph'
      capture: 0
      regex: /(^|\n)([ \t]*\S.*(\n|$))+/
    add new Rule
      name: 'lineBreak'
      regex: /\\\\/
    add new Rule
      name: 'unorderedList'
      capture: 0
      regex: /(^|\n)([ \t]*\*[^*#].*(\n|$)([ \t]*[^\s*#].*(\n|$))*([ \t]*[*#]{2}.*(\n|$))*)+/
    add new Rule
      name: 'orderedList'
      capture: 0
      regex: /(^|\n)([ \t]*#[^*#].*(\n|$)([ \t]*[^\s*#].*(\n|$))*([ \t]*[*#]{2}.*(\n|$))*)+/
    add new Rule
      name: 'listItem'
      capture: 0
      regex: /[ \t]*([*#]).+(\n[ \t]*[^*#\s].*)*(\n[ \t]*\1[*#].+)*/
      replaceRegex: /(^|\n)[ \t]*[*#]/g
      replaceString: '$1'
    add new Rule
      name: 'horizontalRule'
      regex: /(^|\n)\s*----\s*(\n|$)/
    add new Rule
      name: 'image'
      regex: rx.image
      build: (builder, r) ->
        builder.start @name,
          type: 'internal'
          link: r[1]
          title: r[2]?.replace /~(.)/g, '$1'
        builder.end()
    add new Rule
      name: 'table'
      capture: 0
      regex: /(^|\n)(\|.*?[ \t]*(\n|$))+/
    add new Rule
      name: 'tableRow'
      capture: 2
      regex: /(^|\n)(\|.*?)\|?[ \t]*(\n|$)/
    add new Rule
      name: 'tableHeading'
      regex: /\|+=([^|]*)/
      capture: 1
    add new Rule
      name: 'tableCell'
      capture: 1,
      regex: '\\|+([^|~\\[{]*((~(.|(?=\\n)|$)|' +
             '\\[\\[' + rx.link + '(\\|' + rx.linkText + ')?\\]\\]' +
             (if @options?.strict then '' else '|' + rx.image) +
             '|[\\[{])[^|~]*)*)'
    add new Rule
      name: 'nowiki'
      capture: 2
      regex: /(^|\n)\{\{\{\n((.*\n)*?)\}\}\}(\n|$)/
      replaceRegex: /^ ([ \t]*\}\}\})/gm
      replaceString: '$1'
    add new Rule
      name: 'inlineNowiki'
      regex: /\{\{\{(.*?\}\}\}+)/
      capture: 1
      replaceRegex: /\}\}\}$/
      replaceString: ''
    add new Rule
      name: 'singleLine'
      regex: /.+/
      capture: 0
    add new Rule
      name: 'text'
      capture: 0
      regex: /(^|\n)([ \t]*[^\s].*(\n|$))+/
    add new Rule
      name: 'escapedSequence'
      regex: '~(' + rx.rawUri + '|.)'
      capture: 1
    add new Rule
      name: 'escapedSymbol'
      regex: /~(.)/
      capture: 1
    g.bold.children = g.italics.children = g.heading1.children = g.heading2.children = g.heading3.children = g.heading4.children = g.heading5.children = g.heading6.children = g.paragraph.children = g.singleLine.children = g.text.children = [g.escapedSequence, g.bold, g.italics, g.lineBreak, g.url, g.externalLink, g.interwikiLink, g.internalLink, g.inlineNowiki, g.image]
    g.internalLink.children = g.externalLink.children = g.url.children = g.interwikiLink.children = [g.escapedSymbol, g.image]
    g.unorderedList.children = g.orderedList.children = [g.listItem]
    g.listItem.children = [g.unorderedList, g.orderedList]
    g.listItem.fallback = g.text
    g.table.children = [g.tableRow]
    g.tableRow.children = [g.tableHeading, g.tableCell]
    g.tableHeading.children = g.tableCell.children = [g.singleLine]
    @root = new Rule
      children: [g.heading1, g.heading2, g.heading3, g.heading4, g.heading5, g.heading6, g.horizontalRule, g.unorderedList, g.orderedList, g.nowiki, g.table]
      fallback: new Rule {children: [g.paragraph]}
  parse: (builder, data) -> @root.apply builder, data

exports.Parser = Parser
