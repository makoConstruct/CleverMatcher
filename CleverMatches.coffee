#returns null if not a match, or {score, matched:text with match tags inserted}
subsequence = (text, term, hit_tag)->
  uctext = text.toUpperCase()
  ucterm = term.toUpperCase()
  hits = [] #records the position of hits so they can later be tagged
  j = -1 #remembers position of last found character
  
  #do the subsequence match
  score = 1
  for i in [0... ucterm.length]
    l = ucterm[i]
    # continue if l == ' ' #ignore spaces     why would you do that.
    j = uctext.indexOf(l, j+1)     #search for character & update position
    if j == -1  #if it's not found, exclude this item
      return null
    else
      original_char = text.charCodeAt(j)
      #special favor to upper case letters, and letters after a space or an underscore, as these are likely to be the beginning of a word and thus better define the word itself
      if original_char >= 65 and original_char <= 90
        score += 4
      else if j > 0
        previous_char = text.charCodeAt(j - 1)
        if previous_char == 32 or previous_char == 95
          score += 4
      else
        score += 4
      #prefer words longer than 4, very short words don't need autocompletion
      if text.length > 4
        score += 3
      hits.push j
  
  #produce search result with match tags
  i = 0
  splitted_text = []
  last_split = 0
  #divide the string at the insertion points
  while i < hits.length
    #find the end of this contiguous sequence of hits
    ie = i
    loop
      ie += 1
      break if ie >= hits.length or hits[ie] != hits[ie - 1] + 1
    tagstart = hits[i]
    tagend = hits[ie - 1] + 1
    splitted_text.push text.slice last_split, tagstart
    last_split = tagstart
    splitted_text.push text.slice last_split, tagend
    last_split = tagend
    i = ie
  cap = text.slice last_split, text.length
  #join that stuff up
  i = 0
  cumulate = ''
  start_tag = '<span class="'+hit_tag+'">'
  end_tag = '</span>'
  while i < splitted_text.length
    cumulate += splitted_text[i] + start_tag + splitted_text[i + 1] + end_tag
    i += 2
  {score:score,  matched:cumulate + cap}
    
  

class @MatchSet
  constructor: ->
    if arguments.length == 1
      @takeSet arguments[0]
  takeSet: (@set)->
    #@set is like [[text, key]*]
  #returns result array, no longer than nresults, formatted like [{score, matched, text, key}*] and sorted by score
  #score: the matchingness of the result
  #text: the text that was matched
  #matched: the text with span tags inserted around the positions in the result where the search_term matched
  #key: the key of the result that was matched
  seek: (search_term, nresults = 10, hit_tag = 'subsequence_matching')->
    #we sort of assume nresults is going to be small enough that an array is the most performant data structure for collating search results.
    return [] if @set.length == 0 or nresults == 0
    retar = []
    minscore = 0
    for ci in [0 ... @set.length]
      c = @set[ci]
      sr = subsequence c[0], search_term, hit_tag
      # if c[1] == 0 then console.log sr
      if sr and (sr.score > minscore or retar.length < nresults)
        insertat = 0
        for insertat in [0 ... retar.length]
          break if retar[insertat].score < sr.score
        sr.key = c[1]
        sr.text = c[0]
        retar.splice insertat, 0, sr
        if retar.length > nresults
          retar.pop()
        minscore = retar[retar.length-1].score
    retar

@matchset = -> new @MatchSet(arguments...)

#takes an array of strings, indicies serve as the keys in the MatchSet
@matchset_from_strings = (strar)-> new @MatchSet((strar.map (st, i)-> [st, i])...)