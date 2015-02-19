// Generated by CoffeeScript 1.8.0
(function() {
  var isAlphanum, isLowercase, isNumeric, isUppercase, matching, skipMatch, subsequenceMatch;

  subsequenceMatch = function(uctext, ucterm) {
    var char, hits, termi, texti;
    hits = [];
    texti = -1;
    termi = 0;
    while (termi < ucterm.length) {
      char = ucterm.charCodeAt(termi);
      texti = uctext.indexOf(ucterm[termi], texti + 1);
      if (texti === -1) {
        return null;
      }
      hits.push(texti);
      termi += 1;
    }
    return hits;
  };

  skipMatch = function(uctext, ucterm, acry) {
    var ai, ait, char, hits, termi, texti;
    hits = [];
    ai = 0;
    texti = -1;
    termi = 0;
    while (termi < ucterm.length) {
      char = ucterm.charCodeAt(termi);
      ait = ai;
      while (ait < acry.length) {
        if (char === uctext.charCodeAt(acry[ait])) {
          break;
        }
        ait += 1;
      }
      if (ait < acry.length) {
        texti = acry[ait];
        ai = ait + 1;
      } else {
        texti = uctext.indexOf(ucterm[termi], texti + 1);
        while (ai < acry.length && texti > acry[ai]) {
          ai += 1;
        }
        if (texti === -1) {
          return null;
        }
      }
      hits.push(texti);
      termi += 1;
    }
    return hits;
  };

  matching = function(candidate, term, hitTag) {
    var acry, ai, cap, cumulation, endTag, hit, hits, i, ie, ji, lastSplit, outp, splittedText, startTag, tagend, tagstart, text, ucterm, uctext, _i, _j, _k, _len, _ref, _ref1;
    text = candidate.text;
    acry = candidate.acronym;
    uctext = text.toUpperCase();
    ucterm = term.toUpperCase();
    outp = {
      score: 1
    };
    hits = skipMatch(uctext, ucterm, acry) || subsequenceMatch(uctext, ucterm);
    if (!hits) {
      return null;
    }
    ji = -1;
    for (_i = 0, _len = hits.length; _i < _len; _i++) {
      hit = hits[_i];
      ji = acry.indexOf(hit, ji + 1);
      if (ji >= 0) {
        outp.score += ji === 0 ? 48 : 30;
      }
    }
    for (i = _j = 0, _ref = hits.length; 0 <= _ref ? _j < _ref : _j > _ref; i = 0 <= _ref ? ++_j : --_j) {
      if (term.charCodeAt(i) === text.charCodeAt(hits[i])) {
        outp.score += 11;
      }
    }
    ai = 0;
    if (text.length > 4) {
      outp.score += 20;
    }
    if (hitTag) {
      i = 0;
      splittedText = [];
      lastSplit = 0;
      while (i < hits.length) {
        ie = i;
        while (true) {
          ie += 1;
          if (ie >= hits.length || hits[ie] !== hits[ie - 1] + 1) {
            break;
          }
        }
        outp.score += (ie - i - 1) * 18;
        tagstart = hits[i];
        tagend = hits[ie - 1] + 1;
        splittedText.push(text.slice(lastSplit, tagstart));
        lastSplit = tagstart;
        splittedText.push(text.slice(lastSplit, tagend));
        lastSplit = tagend;
        i = ie;
      }
      cap = text.slice(lastSplit, text.length);
      i = 0;
      cumulation = '';
      startTag = '<span class="' + hitTag + '">';
      endTag = '</span>';
      while (i < splittedText.length) {
        cumulation += splittedText[i] + startTag + splittedText[i + 1] + endTag;
        i += 2;
      }
      outp.matched = cumulation + cap;
    } else {
      for (i = _k = 1, _ref1 = hits.length; 1 <= _ref1 ? _k < _ref1 : _k > _ref1; i = 1 <= _ref1 ? ++_k : --_k) {
        if (hits[i - 1] + 1 === hits[i]) {
          outp.score += 18;
        }
      }
    }
    return outp;
  };

  isLowercase = function(charcode) {
    return charcode >= 97 && charcode <= 122;
  };

  isUppercase = function(charcode) {
    return charcode >= 65 && charcode <= 90;
  };

  isNumeric = function(charcode) {
    return charcode >= 48 && charcode <= 57;
  };

  isAlphanum = function(charcode) {
    return (isLowercase(charcode)) || (isUppercase(charcode)) || (isNumeric(charcode));
  };

  this.MatchSet = (function() {
    function MatchSet(termArray, hitTag, matchAllForNothing) {
      this.hitTag = hitTag;
      this.matchAllForNothing = matchAllForNothing;
      this.takeSet(termArray);
    }

    MatchSet.prototype.takeSet = function(termArray) {
      return this.set = (termArray.length > 0 ? termArray[0].constructor === String ? termArray.map(function(st, i) {
        return [st, i];
      }) : termArray : []).map(function(_arg) {
        var ar, charcode, j, key, text;
        text = _arg[0], key = _arg[1];
        return {
          text: text,
          key: key,
          acronym: ((function() {
            var _i, _ref;
            ar = [];
            if (text.length > 0) {
              for (j = _i = 0, _ref = text.length; 0 <= _ref ? _i < _ref : _i > _ref; j = 0 <= _ref ? ++_i : --_i) {
                charcode = text.charCodeAt(j);
                if ((isUppercase(charcode)) || isAlphanum(charcode) && (j === 0 || !isAlphanum(text.charCodeAt(j - 1)))) {
                  ar.push(j);
                }
              }
            }
            return ar;
          })())
        };
      });
    };

    MatchSet.prototype.seek = function(searchTerm, nresults) {
      var c, i, insertat, minscore, ret, retar, sel, sr, _i, _j, _k, _len, _ref, _ref1, _ref2;
      if (nresults == null) {
        nresults = 10;
      }
      if (this.set.length === 0 || nresults === 0) {
        return [];
      }
      if (searchTerm.length === 0) {
        if (this.matchAllForNothing) {
          ret = [];
          for (i = _i = 0, _ref = Math.min(nresults, this.set.length); 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
            sel = this.set[i];
            ret.push({
              score: 1,
              matched: sel.text,
              text: sel.text,
              key: sel.key
            });
          }
          return ret;
        } else {
          return [];
        }
      }
      retar = [];
      minscore = 0;
      _ref1 = this.set;
      for (_j = 0, _len = _ref1.length; _j < _len; _j++) {
        c = _ref1[_j];
        sr = matching(c, searchTerm, this.hitTag);
        if (sr && (sr.score > minscore || retar.length < nresults)) {
          insertat = 0;
          for (insertat = _k = 0, _ref2 = retar.length; 0 <= _ref2 ? _k < _ref2 : _k > _ref2; insertat = 0 <= _ref2 ? ++_k : --_k) {
            if (retar[insertat].score < sr.score) {
              break;
            }
          }
          sr.key = c.key;
          sr.text = c.text;
          retar.splice(insertat, 0, sr);
          if (retar.length > nresults) {
            retar.pop();
          }
          minscore = retar[retar.length - 1].score;
        }
      }
      return retar;
    };

    MatchSet.prototype.remove = function(item) {
      var id;
      id = this.set.indexOf(item);
      if (id >= 0) {
        return this.set.splice(id, 1);
      }
    };

    MatchSet.prototype.add = function(item) {};

    MatchSet.prototype.seekBestKey = function(term) {
      var res;
      res = this.seek(term, 1);
      if (res.length > 0) {
        return res[0].key;
      } else {
        return null;
      }
    };

    return MatchSet;

  })();

  this.matchset = function(ar, hitTag, matchAllForNothing) {
    if (hitTag == null) {
      hitTag = 'subsequence_match';
    }
    if (matchAllForNothing == null) {
      matchAllForNothing = false;
    }
    return new this.MatchSet(ar, hitTag, matchAllForNothing);
  };

}).call(this);

//# sourceMappingURL=CleverMatcher.js.map
