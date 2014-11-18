// Generated by CoffeeScript 1.4.0
(function() {
  var subsequence;

  subsequence = function(text, term, hit_tag) {
    var cap, cumulate, end_tag, hits, i, ie, j, l, last_split, original_char, previous_char, score, splitted_text, start_tag, tagend, tagstart, ucterm, uctext, _i, _ref;
    uctext = text.toUpperCase();
    ucterm = term.toUpperCase();
    hits = [];
    j = -1;
    score = 1;
    for (i = _i = 0, _ref = ucterm.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      l = ucterm[i];
      j = uctext.indexOf(l, j + 1);
      if (j === -1) {
        return null;
      } else {
        original_char = text.charCodeAt(j);
        if (original_char >= 65 && original_char <= 90) {
          score += 4;
        } else if (j > 0) {
          previous_char = text.charCodeAt(j - 1);
          if (previous_char === 32 || previous_char === 95) {
            score += 4;
          }
        } else {
          score += 4;
        }
        if (text.length > 4) {
          score += 3;
        }
        hits.push(j);
      }
    }
    i = 0;
    splitted_text = [];
    last_split = 0;
    while (i < hits.length) {
      ie = i;
      while (true) {
        ie += 1;
        if (ie >= hits.length || hits[ie] !== hits[ie - 1] + 1) {
          break;
        }
      }
      tagstart = hits[i];
      tagend = hits[ie - 1] + 1;
      splitted_text.push(text.slice(last_split, tagstart));
      last_split = tagstart;
      splitted_text.push(text.slice(last_split, tagend));
      last_split = tagend;
      i = ie;
    }
    cap = text.slice(last_split, text.length);
    i = 0;
    cumulate = '';
    start_tag = '<span class="' + hit_tag + '">';
    end_tag = '</span>';
    while (i < splitted_text.length) {
      cumulate += splitted_text[i] + start_tag + splitted_text[i + 1] + end_tag;
      i += 2;
    }
    return {
      score: score,
      matched: cumulate + cap
    };
  };

  this.MatchSet = (function() {

    function MatchSet() {
      if (arguments.length === 1) {
        this.takeSet(arguments[0]);
      }
    }

    MatchSet.prototype.takeSet = function(set) {
      this.set = set;
    };

    MatchSet.prototype.seek = function(search_term, nresults, hit_tag) {
      var c, ci, insertat, minscore, retar, sr, _i, _j, _ref, _ref1;
      if (nresults == null) {
        nresults = 10;
      }
      if (hit_tag == null) {
        hit_tag = 'subsequence_matching';
      }
      if (this.set.length === 0 || nresults === 0) {
        return [];
      }
      retar = [];
      minscore = 0;
      for (ci = _i = 0, _ref = this.set.length; 0 <= _ref ? _i < _ref : _i > _ref; ci = 0 <= _ref ? ++_i : --_i) {
        c = this.set[ci];
        sr = subsequence(c[0], search_term, hit_tag);
        if (sr && (sr.score > minscore || retar.length < nresults)) {
          insertat = 0;
          for (insertat = _j = 0, _ref1 = retar.length; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; insertat = 0 <= _ref1 ? ++_j : --_j) {
            if (retar[insertat].score < sr.score) {
              break;
            }
          }
          sr.key = c[1];
          sr.text = c[0];
          retar.splice(insertat, 0, sr);
          if (retar.length > nresults) {
            retar.pop();
          }
          minscore = retar[retar.length - 1].score;
        }
      }
      return retar;
    };

    return MatchSet;

  })();

  this.matchset = function() {
    return (function(func, args, ctor) {
      ctor.prototype = func.prototype;
      var child = new ctor, result = func.apply(child, args);
      return Object(result) === result ? result : child;
    })(this.MatchSet, arguments, function(){});
  };

  this.matchset_from_strings = function(strar) {
    return (function(func, args, ctor) {
      ctor.prototype = func.prototype;
      var child = new ctor, result = func.apply(child, args);
      return Object(result) === result ? result : child;
    })(this.MatchSet, strar.map(function(st, i) {
      return [st, i];
    }), function(){});
  };

}).call(this);
