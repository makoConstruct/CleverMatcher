
#if not a match, returns null, else {score, matched:text with match tags inserted}
matching = (candidate, term, hit_tag)->
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
		if char == uctext.charCodeAt cacy[ai] #we can match a word beginning. leap there, give acropoints
			texti = cacy[ai]
			ai += 1
			score += if term.charCodeAt(termi) == text.charCodeAt(cacy[ai]) then 41 else 30 #scores more if the case is the same
		else
			texti = uctext.indexOf(ucterm[termi], texti + 1) #search for character & update position
			#ensure that the ai stays ahead of the texti, or else invalidate it
			while texti > cacy[ai]
				ai += 1
				if ai >= cacy.length
					ai = -1
					break
			if texti == -1  #if it's not found, this term doesn't match the text
				return null
		hits.push texti
		termi += 1
	if hits.length != term.length
		return null
	
	#post hoc scoring
	#bonus points for matches at word beginnings
	for hit in hits
		original_char = text.charCodeAt(hit)
	#prefers longer words as short ones rarely need autocompletion
	if text.length > 4
		score += 20
	
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
		#points are scored for contiguous hits
		score += (ie - i - 1)*7
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
	cumulation = ''
	start_tag = '<span class="'+hit_tag+'">'
	end_tag = '</span>'
	while i < splitted_text.length
		cumulation += splitted_text[i] + start_tag + splitted_text[i + 1] + end_tag
		i += 2
	{score:score,  matched:cumulation + cap}

is_lowercase = (charcode)-> (charcode >= 97 and charcode <= 122)
is_uppercase = (charcode)-> (charcode >= 65 and charcode <= 90)
is_numeric = (charcode)-> (charcode >= 48 and charcode <= 57)

is_alphanum = (charcode)-> (is_lowercase charcode) or (is_uppercase charcode) or (is_numeric charcode)

class @MatchSet
	constructor: (args...)->
		if args.length == 1
			@take_set args[0]
	take_set: (term_array)->
		@set = new Array(term_array.length)
		for i in [0 ... term_array.length]
			text = term_array[i][0]
			@set[i] =
				text:text
				key:term_array[i][1]
				acronym:(
					ar = []
					if text.length > 0
						for j in [0 ... text.length]
							charcode = text.charCodeAt j
							ar.push j if (
								(is_uppercase charcode) or
								is_alphanum(charcode) and
								(j == 0 or !is_alphanum(text.charCodeAt(j - 1))) #not letter
							)
					ar
				)
		#@set is like [{acronym, text, key}*] where acronym is an array of the indeces of the beginnings of the words in the text
	seek: (search_term, nresults = 10, hit_tag = 'subsequence_matching')->
		#we sort of assume nresults is going to be small enough that an array is the most performant data structure for collating search results.
		return [] if @set.length == 0 or nresults == 0
		retar = []
		minscore = 0
		for ci in [0 ... @set.length]
			c = @set[ci]
			sr = matching c, search_term, hit_tag
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
	
	seek_best_key: (term)->
		res = @seek(term, 1)
		if res.length > 0
			res[0].key
		else
			null
		
@matchset = (args)-> new @MatchSet(args)

#takes an array of strings, indicies serve as the keys in the MatchSet
@matchset_from_strings = (strar)-> new @MatchSet((strar.map (st, i)-> [st, i]))
