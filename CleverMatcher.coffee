substringMatch = (uctext, ucterm)-> #returns hits array
	#simple subsequence match
	hits = []
	texti = -1
	termi = 0
	while termi < ucterm.length
		char = ucterm.charCodeAt termi
		texti = uctext.indexOf(ucterm[termi], texti + 1) #search for character & update position
		if texti == -1  #if it's not found, this term doesn't match the text
			return null
		hits.push texti
		termi += 1
	hits

#subsequence match that prefers to go by word beginnings
skipMatch = (uctext, ucterm, acry)-> #returns hits array
	#possible methods to explore once performance testing: try having it branch every time it faces a choice between skipping ahead to match an initial and continuing with a greedy substring match, get better results.
	hits = []
	ai = 0
	texti = -1
	termi = 0
	while termi < ucterm.length
		char = ucterm.charCodeAt termi
		#see if we can match a word beginning
		ait = ai
		while ait < acry.length
			if char == uctext.charCodeAt acry[ait]
				break
			ait += 1
		if ait < acry.length #we can match a word beginning. leap there
			texti = acry[ait]
			ai = ait + 1
		else
			#normal subsequence matching
			texti = uctext.indexOf(ucterm[termi], texti + 1) #search for character & update position
			#ensure that the ai stays ahead of the texti, or else invalidate it
			while ai < acry.length and texti > acry[ai]
				ai += 1
			if texti == -1  #if it's not found, this term doesn't match the text
				return null
		hits.push texti
		termi += 1
	hits


#if not a match, returns null, else {score, matched:text with match tags inserted}
matching = (candidate, term, hitTag)->
	text = candidate.text
	acry = candidate.acronym
	uctext = text.toUpperCase()
	ucterm = term.toUpperCase()
	outp = {score:1}
	
	hits = skipMatch(uctext, ucterm, acry) || substringMatch(uctext, ucterm)
	return null if !hits
		
	#post hoc scoring
	#points for matches at word beginnings
	ji = -1
	for acro in acry
		ji = hits.indexOf acro, ji+1
		if ji >= 0
			outp.score += 30
	#points for matching the case
	for i in [0 ... hits.length]
		if term.charCodeAt(i) == text.charCodeAt(hits[i])
			outp.score += 11
	ai = 0
	#prefers longer words as short ones rarely need autocompletion
	if text.length > 4
		outp.score += 20
	
	
	if hitTag
		#produce search result with match tags
		i = 0
		splittedText = []
		lastSplit = 0
		#divide the string at the insertion points
		while i < hits.length
			#find the end of this contiguous sequence of hits
			ie = i
			loop
				ie += 1
				break if ie >= hits.length or hits[ie] != hits[ie - 1] + 1
			#points are scored for contiguous hits
			outp.score += (ie - i - 1)*18
			tagstart = hits[i]
			tagend = hits[ie - 1] + 1
			splittedText.push text.slice lastSplit, tagstart
			lastSplit = tagstart
			splittedText.push text.slice lastSplit, tagend
			lastSplit = tagend
			i = ie
		cap = text.slice lastSplit, text.length
		#join that stuff up
		i = 0
		cumulation = ''
		startTag = '<span class="'+hitTag+'">'
		endTag = '</span>'
		while i < splittedText.length
			cumulation += splittedText[i] + startTag + splittedText[i + 1] + endTag
			i += 2
		outp.matched = cumulation + cap
	else
		#just add the contiguosity points
		for i in [1 ... hits.length]
			if hits[i - 1] + 1 == hits[i]
				outp.score += 18
	outp

isLowercase = (charcode)-> (charcode >= 97 and charcode <= 122)
isUppercase = (charcode)-> (charcode >= 65 and charcode <= 90)
isNumeric = (charcode)-> (charcode >= 48 and charcode <= 57)

isAlphanum = (charcode)-> (isLowercase charcode) or (isUppercase charcode) or (isNumeric charcode)

class @MatchSet
	constructor: (set, @hitTag)->
		@takeSet set
	takeSet: (termArray)-> #allows [[text, key]*] or [text*], in the latter case a text's index in the input array will be its key
		#shunt termArray into the correct form
		if termArray.length > 0
			if termArray[0].constructor == String
				termArray = (termArray.map (st, i)-> [st, i])
		@set = new Array(termArray.length)
		for i in [0 ... termArray.length]
			text = termArray[i][0]
			@set[i] =
				text:text
				key:termArray[i][1]
				acronym:(
					ar = []
					if text.length > 0
						for j in [0 ... text.length]
							charcode = text.charCodeAt j
							ar.push j if (
								(isUppercase charcode) or
								isAlphanum(charcode) and
								(j == 0 or !isAlphanum(text.charCodeAt(j - 1))) #not letter
							)
					ar
				)
		#@set is like [{acronym, text, key}*] where acronym is an array of the indeces of the beginnings of the words in the text
	seek: (searchTerm, nresults = 10)->
		#we sort of assume nresults is going to be small enough that an array is the most performant data structure for collating search results.
		return [] if @set.length == 0 or nresults == 0 or searchTerm.length == 0
		retar = []
		minscore = 0
		for ci in [0 ... @set.length]
			c = @set[ci]
			sr = matching c, searchTerm, @hitTag
			if sr and (sr.score > minscore or retar.length < nresults)
				insertat = 0
				for insertat in [0 ... retar.length]
					break if retar[insertat].score < sr.score
				sr.key = c.key
				sr.text = c.text
				retar.splice insertat, 0, sr
				if retar.length > nresults
					retar.pop()
				minscore = retar[retar.length-1].score
		retar
	
	seekBestKey: (term)->
		res = @seek(term, 1)
		if res.length > 0
			res[0].key
		else
			null
		
@matchset = (ar, hitTag = 'subsequence_match')-> new @MatchSet(ar, hitTag)
