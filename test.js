module('MatchSet');

function expectTheseKeysFirst(matchSet, term, keys){
  rs = matchSet.seek(term, keys.length);
  for (I = 0, Len = rs.length; I < Len; I++) {
    mr = rs[I];
    ok((keys.indexOf(mr.key) >= 0), mr.text + " is in the top results");
  }
}

test('basic actuation', function(){
  ms = new MatchSet([['hugssssssssssomg', 0]]);
  equal(ms.seekBestKey('h'), 0);
});

test("words without the letters in the terms don't get through", function() {
  var ms, res;
  ms = matchset(['mena', 'hobo', 'duludd']);
  res = ms.seek('o');
  ok(res.length === 1 && res[0].key === 1);
});

test('matches at word beginnings are prefered', function() {
  var expectedKeys, mr, ms, rs, I, Len, Ref, Results;
  ms = matchset([['ihel', 0], ['holo', 1], ['Respected Madame Shomo', 2], ['oloh', 3], ['...hanged', 4], ['  highestpanther', 5]]);
  expectTheseKeysFirst(ms, 'h', [1, 4, 5]);
});