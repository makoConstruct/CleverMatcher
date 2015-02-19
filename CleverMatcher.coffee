subsequenceMatch = (uctext, ucterm)-> #returns array of the indices in uctext where the letters of ucterm were found. EG: subsequenceMatch("nothing", "ni") returns [0, 4]. subsequenceMatch("nothing", "a") returns null.
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


skipMatch = (uctext, ucterm, acry)->
	#subsequence match that tries to match the letters at the beginnings of the words (IE, after a space, an underscore, or camelcase hump) instead of the first letters it finds when it can. Those words are specified in acry (short for acronym), which is an array of the indexes of the word beginnings in uctext.
	#returns the same kind of hits array as subsequenceMatch
	
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


matching = (candidate, term, hitTag)->
	#this method tries skipMatch, then subsequenceMatch if there is no skipMatch. It then scores the result.
	#if no match, returns null, else {score, matched:<text with match tags inserted>}
	text = candidate.text
	acry = candidate.acronym
	uctext = text.toUpperCase()
	ucterm = term.toUpperCase()
	outp = {score:1}
	
	hits = skipMatch(uctext, ucterm, acry) || subsequenceMatch(uctext, ucterm)
	return null if !hits
		
	#post hoc scoring
	#points for matches at word beginnings
	ji = -1
	for hit in hits
		ji = acry.indexOf hit, ji+1
		if ji >= 0 then outp.score +=
			if ji == 0
				48
			else
				30
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
		#otherwise just add the contiguosity points
		for i in [1 ... hits.length]
			if hits[i - 1] + 1 == hits[i]
				outp.score += 18
	outp

isLowercase = (charcode)-> (charcode >= 97 and charcode <= 122)
isUppercase = (charcode)-> (charcode >= 65 and charcode <= 90)
isNumeric = (charcode)-> (charcode >= 48 and charcode <= 57)

isAlphanum = (charcode)-> (isLowercase charcode) or (isUppercase charcode) or (isNumeric charcode)

class @MatchSet
	constructor: (termArray, @hitTag, @matchAllForNothing)->
		@takeSet termArray
	takeSet: (termArray)-> #allows [[text, key]*] or [text*], in the latter case a text's index in the input array will be its key
		#does not currently maintain an index..
		#shunt termArray into the correct form
		@set = (
			if termArray.length > 0
				if termArray[0].constructor == String
					termArray.map (st, i)-> [st, i]
				else
					termArray
			else []
		).map ([text, key])->
			text:text
			key:key
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
	seek: (searchTerm, nresults = 10)-> #returns like [{score, matched:<the text with match spans inserted where a letter matched>, text, key}*]
		#we sort of assume nresults is going to be small enough that an array is the most performant data structure for collating search results.
		return [] if @set.length == 0 or nresults == 0
		if searchTerm.length == 0
			if @matchAllForNothing
				ret = []
				for i in [0 ... Math.min(nresults, @set.length)]
					sel = @set[i]
					ret.push {
						score: 1 #shrug
						matched: sel.text
						text: sel.text
						key: sel.key
					}
				return ret
			else
				return []
		retar = []
		minscore = 0
		for c in @set
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
	remove: (item)-> #O(@set.length)
		id = @set.indexOf item
		if id >= 0
			@set.splice id, 1
	add: (item)->
		
	seekBestKey: (term)->
		res = @seek(term, 1)
		if res.length > 0
			res[0].key
		else
			null
		
@matchset = (ar, hitTag = 'subsequence_match', matchAllForNothing = false)-> new @MatchSet(ar, hitTag, matchAllForNothing)
