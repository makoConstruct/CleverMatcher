module('MatchSet');

function expect_these_keys_first(match_set, term, keys){
  rs = match_set.seek(term, keys.length);
  for (_i = 0, _len = rs.length; _i < _len; _i++) {
    mr = rs[_i];
    ok((keys.indexOf(mr.key) >= 0), mr.text + " is in the top results");
  }
}

test('basic actuation', function(){
	ms = new MatchSet([['hugssssssssssomg', 0]]);
	equal(ms.seek_best_key('h'), 0);
});

test("words without the letters in the terms don't get through", function() {
  var ms, res;
  ms = matchset_from_strings(['mena', 'hobo', 'duludd']);
  res = ms.seek('o');
  ok(res.length === 1 && res[0].key === 1);
});

test('matches at word beginnings are prefered', function() {
  var expected_keys, mr, ms, rs, _i, _len, _ref, _results;
  ms = matchset([['ihel', 0], ['holo', 1], ['Respected Madame Shomo', 2], ['oloh', 3], ['...hanged', 4], ['  highestpanther', 5]]);
  expect_these_keys_first(ms, 'h', [1, 4, 5]);
});