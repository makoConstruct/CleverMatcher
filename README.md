##CleverMatcher

CleverMatcher is (or at least as a *stone soup*, aspires to be) an extremely efficient fuzzy text search for applications with autocompletion widgets. It's largely inspired by Sublime Text's autocompletion behavior, having a developed preference for matching acronym shorthands to their expansions.

###Example
```
var ms = matchset([
  ['Binding Lantern Smith', 0],
  ['Hopeful Woods', 1],
  ['blustery_green', 2],
  ['Holy Sword', 3]
]);

ms.seek('bl');
```
yields 
```
[ { score: 15,
    matched: '<span class="subsequence_matching">B</span>inding <span class="subsequence_matching">L</span>antern Smith',
    key: 0,
    text: 'Binding Lantern Smith' },
  { score: 11,
    matched: '<span class="subsequence_matching">bl</span>ustery_green',
    key: 2,
    text: 'blustery_green' } ]
```

###API
There is a simplified matchest construction function
```
var ms = matchset_from_strings(['Binding Lantern Smith', 'Hopeful Woods', 'blustery_green', 'Holy Sword']);
```
this will produce a matchset equivalent to the above; each entry's key will be as its index in the input array.


You can control the number of results you'll get, as well as the css class to assign to the spans in matched texts. Where ms is as previously specified,

```
ms.seek('hs', 1, 'matched');
```
returns
```
[ { score: 15,
    matched: '<span class="matched">H</span>olly <span class="matched">S</span>word',
    key: 3,
    text: 'Holy Sword' } ]
```