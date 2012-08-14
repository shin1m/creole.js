match = (rx, source, i) ->
  rx.lastIndex = i
  rx.exec source

skipWhitespace = (source, i) ->
  rx = /[\t ]*/g
  rx.lastIndex = i
  rx.test source
  rx.lastIndex

linkOptions = (internal, external, interwiki) ->
  if internal?
    type: 'internal'
    link: internal
  else if external?
    type: 'external'
    link: external
  else
    type: 'interwiki'
    link: interwiki

style_NONE = 0
style_BOLD = 1
style_ITALICS = 2
style_BOLD_ITALICS = 3
style_ITALICS_BOLD = 4

linkPattern = '[^\\]|~\\n]*(?:(?:\\](?!\\])|~.)[^\\]|~\\n]*)*'
urlPrefix = '\\b(?:(?:https?|ftp)://|mailto:)'
linkPatterns = [
  '(' + urlPrefix + linkPattern + ')'
  '([\\w.]+:' + linkPattern + ')'
  '(' + linkPattern + ')'
].join('|')
rawUrl = urlPrefix + '\\S*[^\\s!"\',.:;?]'
image = '\\{\\{(?:' + linkPatterns + ')(?:\\|([^\\}~\\n]*(?:(?:\\}(?!\\})|~.)[^\\}~\\n]*)*))?\\}\\}'
linkTextMarkups = [
  '\\*\\*'
  '\\/\\/'
  '\\\\\\\\'
  '\\{\\{\\{.*?\\}\\}\\}+'
  image
].join('|')
inLinkText = new RegExp '(\\]\\]|\\n|$)|' + linkTextMarkups + '|~.', 'g'
textMarkups = [
  linkTextMarkups
  '\\[\\[(?:' + linkPatterns + ')(?:\\||\\]\\])'
  rawUrl
  '<<[A-Za-z_]\\w*'
  '~(?:' + rawUrl + '|.)'
].join('|')
inTableCell = new RegExp '(\\||\\n|$)|' + textMarkups, 'g'
headingRuleTable = '={1,6}[\\t ]|----[\\t ]*(?:\\n|$)|\\|'
itemPrefixes = headingRuleTable + '|[*#]*(?:\\*(?!\\*)|#(?!#))'
inListItem = new RegExp '(\\n(?:\\n|[\\t ]*(?:' + itemPrefixes + ')|\\{\\{\\{\\n)|$)|' + textMarkups, 'g'
rootPrefixes = headingRuleTable + '|\\*(?!\\*)|#(?!#)'
inParagraph = new RegExp '(\\n(?:\\n|[\\t ]*(?:' + rootPrefixes + ')|\\{\\{\\{\\n)|$)|' + textMarkups, 'g'
inRoot = new RegExp '([\\t ]*)(' + rootPrefixes + '|(.?))', 'g'

parseLine = (rx, target, source, i, other) ->
  style = style_NONE
  while true
    result = match rx, source, i
    target.text source.substring(i, result.index) if result.index > i
    if result[1]?
      switch style
        when style_BOLD, style_ITALICS
          target.end()
        when style_BOLD_ITALICS, style_ITALICS_BOLD
          target.end()
          target.end()
      return result.index
    i = rx.lastIndex
    switch result[0].substr(0, 2)
      when '**'
        switch style
          when style_BOLD
            target.end()
            style = style_NONE
          when style_ITALICS
            target.start 'bold'
            style = style_ITALICS_BOLD
          when style_BOLD_ITALICS
            target.end()
            target.end()
            style = style_NONE
          when style_ITALICS_BOLD
            target.end()
            style = style_ITALICS
          else
            target.start 'bold'
            style = style_BOLD
      when '//'
        switch style
          when style_BOLD
            target.start 'italics'
            style = style_BOLD_ITALICS
          when style_ITALICS
            target.end()
            style = style_NONE
          when style_BOLD_ITALICS
            target.end()
            style = style_BOLD
          when style_ITALICS_BOLD
            target.end()
            target.end()
            style = style_NONE
          else
            target.start 'italics'
            style = style_ITALICS
      when '\\\\'
        target.start 'lineBreak'
        target.end()
      when '{{'
        if result[0].charAt(2) == '{'
          target.start 'inlineNowiki'
          target.text source.substring(result.index + 3, i - 3)
        else
          options = linkOptions result[4], result[2], result[3]
          options.title = result[5]?.replace /~(.)/g, '$1'
          target.start 'image', options
        target.end()
      else
        i = other target, result, i

parseLinkText = (target, source, i) ->
  i = parseLine inLinkText, target, source, i, (target, result, i) ->
    target.start 'escaped'
    target.text result[0].charAt(1)
    target.end()
    i
  switch source.charAt(i)
    when '\n'
      ++i
    when ']'
      ++i
      ++i if source.charAt(i) == ']'
  i

parseMacroParameters = (source, i) ->
  rx = />>|[\t ]+([A-Za-z_]\w*)='([^'\\]*(?:\\.|[^'\\])*)'|(.?)/g
  parameters = {}
  while true
    result = match rx, source, i
    return null if result[3]?
    i = rx.lastIndex
    break if result[0].charAt(0) == '>'
    parameters[result[1]] = result[2].replace /\\(.)/g, '$1'
  [i, parameters]

parseText = (rx, target, source, i) ->
  i = parseLine rx, target, source, i, (target, result, i) ->
    switch result[0].charAt(0)
      when '['
        target.start 'link', linkOptions(result[8], result[6], result[7])
        if result[0].charAt(result[0].length - 1) == '|'
          i = parseLinkText target, source, i
        else
          target.text result[6] ? result[7] ? result[8]
      when '<'
        ip = parseMacroParameters source, i
        if ip
          i = ip[0]
          target.start 'macro', {name: result[0].substr(2), parameters: ip[1]}
        else
          target.text result[0]
          return i
      when '~'
        target.start 'escaped'
        target.text result[0].substr(1)
      else
        target.start 'url', link: result[0]
    target.end()
    i

parseHeading = (n, target, source, i) ->
  target.start 'heading' + (n - 1)
  i += n
  rx = /(?:[\t ]=+[\t ]*)?(?:\n|$)/g
  result = match rx, source, i
  target.text source.substring(i, result.index)
  target.end()
  rx.lastIndex

parseTableRow = (target, source, i) ->
  target.start 'tableRow'
  while true
    if source.charAt(++i) == '='
      ++i
      target.start 'tableHeading'
    else
      i = skipWhitespace source, i
      break if source.charAt(i) == '' || source.charAt(i) == '\n'
      target.start 'tableCell'
    i = parseText inTableCell, target, source, i
    target.end()
    break unless source.charAt(i) == '|'
  target.end()
  ++i if source.charAt(i) == '\n'
  i

parseTable = (target, source, i) ->
  target.start 'table'
  while true
    i = parseTableRow target, source, i
    j = skipWhitespace source, i
    break unless source.charAt(j) == '|'
    i = j
  target.end()
  i

parseList = (prefix, target, source, i) ->
  type = prefix.charAt prefix.length - 1
  target.start if type == '*' then 'unorderedList' else 'orderedList'
  rx = /(?:\*(?!\*)|#(?!#))|(.*)/g
  b = true
  while b
    target.start 'listItem'
    i = parseText inListItem, target, source, i + prefix.length
    ++i if source.charAt(i) == '\n'
    while true
      j = skipWhitespace source, i
      unless source.substr(j, prefix.length) == prefix
        b = false
        break
      result = match rx, source, j + prefix.length
      if result[1]?
        if result[1] == type
          b = false
        else
          i = j
        break
      i = parseList prefix + result[0], target, source, j
    target.end()
  target.end()
  i

parseNowiki = (target, source, i) ->
  target.start 'nowiki'
  rx = /\n\}\}\}(?:\n|$)|$/g
  result = match rx, source, i
  target.text source.substring(i, result.index).replace(/^ ([\t ]*\}\}\})/gm, '$1')
  target.end()
  rx.lastIndex

parseParagraph = (target, source, i) ->
  target.start 'paragraph'
  i = parseText inParagraph, target, source, i
  target.end()
  if source.charAt(i) == '\n'
    ++i
    ++i if source.charAt(i) == '\n'
  i

parse = (target, source) ->
  n = source.length
  i = 0
  while i < n
    if source.substr(i, 4) == '{{{\n'
      i = parseNowiki target, source, i + 4
    else if source.charAt(i) == '\n'
      ++i
    else
      result = match inRoot, source, i
      i += result[1].length
      if result[3]?
        i = parseParagraph target, source, i
      else
        switch result[2].charAt(0)
          when '='
            i = parseHeading result[2].length, target, source, i
          when '-'
            target.start 'horizontalRule'
            target.end()
            i += result[2].length
          when '|'
            i = parseTable target, source, i
          else
            i = parseList result[2], target, source, i

exports = module?.exports ? {}
window.creole = exports if window?
exports.parse = parse
