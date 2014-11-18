##CleverMatches

CleverMatches is (or at least as a *stone soup*, aspires to be) an efficient fuzzy text search for applications with autocompletion widgets.

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
You can control the max number of results you'll get, and the name of the class to use in the spans in matched texts

```
ms.seek('hs', 1, 'matched');
```
returns
```
[ { score: 15,
    matched: '<span class="matched">H</span>olly <span clas"matched">S</span>word',
    key: 3,
    text: 'Holy Sword' } ]
```
