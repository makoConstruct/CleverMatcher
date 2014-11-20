
#if not a match, returns null, else {score, matched:text with match tags inserted}
matching = (candidate, term, hitTag)->
	text = candidate.text
	cacy = candidate.acronym
	uctext = text.toUpperCase()
	ucterm = term.toUpperCase()
	score = 1
	
	#subsequence match that prefers to go by word beginnings
	hits = [] #records the position of hits so they can later be tagged
	ai = 0
	texti = -1
	termi = 0
	while termi < ucterm.length
		char = ucterm.charCodeAt termi
		if ai < cacy.length and char == uctext.charCodeAt cacy[ai] #we can match a word beginning. leap there, give acropoints
			texti = cacy[ai]
			score += if term.charCodeAt(termi) == text.charCodeAt(cacy[ai]) then 41 else 30 #scores more if the case is the same
			ai += 1
		else
			texti = uctext.indexOf(ucterm[termi], texti + 1) #search for character & update position
			#ensure that the ai stays ahead of the texti, or else invalidate it
			while ai < cacy.length and texti > cacy[ai]
				ai += 1
			if texti == -1  #if it's not found, this term doesn't match the text
				return null
		hits.push texti
		termi += 1
	if hits.length != term.length
		return null
	
	#post hoc scoring
	#bonus points for matches at word beginnings
	for hit in hits
		originalChar = text.charCodeAt(hit)
	#prefers longer words as short ones rarely need autocompletion
	if text.length > 4
		score += 20
	
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
		score += (ie - i - 1)*17
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
	{score:score,  matched:cumulation + cap}

isLowercase = (charcode)-> (charcode >= 97 and charcode <= 122)
isUppercase = (charcode)-> (charcode >= 65 and charcode <= 90)
isNumeric = (charcode)-> (charcode >= 48 and charcode <= 57)

isAlphanum = (charcode)-> (isLowercase charcode) or (isUppercase charcode) or (isNumeric charcode)

class @MatchSet
	constructor: (args...)->
		if args.length == 1
			@takeSet args[0]
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
	seek: (searchTerm, nresults = 10, hitTag = 'subsequence_matching')->
		#we sort of assume nresults is going to be small enough that an array is the most performant data structure for collating search results.
		return [] if @set.length == 0 or nresults == 0 or searchTerm.length == 0
		retar = []
		minscore = 0
		for ci in [0 ... @set.length]
			c = @set[ci]
			sr = matching c, searchTerm, hitTag
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
		
@matchset = (args)-> new @MatchSet(args)
