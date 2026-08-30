# NS Coding Style Notes

The style customarily used throughout NS scripts and documentation has developed over more than a decade of experience tormenting the LSL Mono VM. It is laden with idiosyncrasies. This document aims not to justify or encourage them, but merely to explain them.

# Formatting Style: "Condensed" K\&R Indentation

The K\&R indentation style prescribes that opening braces should follow flow control operators on the same line:

```
if (x) {
```

The NS style extends this to all blocks:

```
default {  
    state_entry() {
```

It also removes spaces from between flow control operators and their following parenthesis, for consistency with the appearance of functions:

```
if(x) {
```

This habit is common among former BASIC programmers. Most BASIC development environments perform tokenization and linting on a line-by-line basis during the editing process, and will eat stray whitespace.

Tab characters are generally used over spaces. The tab stop is set at 4\. SL's script editor window doesn't like this very much (it often causes the Firestorm preprocessor's error hints to yield an invalid position), but when using an external editor, it means pressing Backspace to delete a level of indentation is much easier.

# Program Structure

LSL is not well-suited to the Mono VM. The bytecode generation process has several dire "gotchas" where simple statements result in ominous amounts of binary for fairly innocuous-seeming pieces of text. \[[Source](https://wiki.secondlife.com/wiki/Lua_FAQ#You_said_Lua_runs_LSL_faster_than_Mono?_It_uses_less_memory?_How?_I'm_suspicious.)\] Function calls and chat messages are both particularly bad—the boilerplate required to add or remove a stack frame is immense, and sending a single chat message requires an asynchronous 'await,' to ensure that the chat messages are dispatched before execution continues. Moreover almost no static optimization is done: a single spurious pair of parentheses wrapped around an expression will have a measurable impact on the compiled code. These deficiencies were the primary reason that Mono scripts were given four times the memory as scripts running on the vintage pre-Mono VM.

Consequently, industry-standard best practices—like breaking code up into many small, modular functions—are ill-suited to LSL. Maximizing the available resources sometimes requires treating the VM like an embedded system; this can be summed up with a few simple strategies:

1. If a function is called several times within a short space and nowhere else in your code, consider restructuring the surrounding code into a loop, so that there is only one function call. Then, embed the function body within that loop.

2. Goto statements (jump) can break out of nested contexts, but not into new contexts or other functions. If you have many branches of code that all end up calling the same function (such as an appearance update that triggers after many different inputs) then this could be turned into a jump into a static block of code at the end of the event handler or function:

```
listen(integer c, string n, key id, string m) {  
	if(m == "on") {  
		power_on = 1;  
		jump update;  
	} else if(m == "off") {  
		power_on = 0;  
		jump update;  
	}  
	jump end; // a simple 'return' here causes a warning about unreachable code  
	@update;  
	// do update here  
@end;  
}
```

3. List structures are horrifyingly memory-inefficient. Storing a key value in a list takes 102 bytes, but storing the same value as a string in the same list costs only 90 bytes. \[[Source](https://wiki.secondlife.com/wiki/LSL_Script_Memory)\] LSL will automatically cast between strings and keys—without any overhead—except in a handful of niche situations. For example, `llParticleSystem()` will complain if it is given a `string` instead of a `key`, or an `integer` instead of a `float`. (There is no exhaustive catalog listing these annoyances, but they are rare.) Whenever possible, use JSON if you need to build an associative list or a list of data records (i.e. something that would be an array of `struct`s in C).

Without JSON:

```
	// format: name, fruit, color, number
	list favorites = [
		"Bob", "apple", "red", 3,
		"Jane", "guava", "fuchsia", 69
	];
	
	// retrieving a single value:
	integer i = index(favorites, "Jane");
	if(~i)
		echo("Jane's favorite color is: " + gets(favorites, i + 2));
	else
		echo("Jane doesn't exist!");
	
	// iterating over all:
	integer i = count(favorites);
	while(i > 0) {
		i -= 3;
		echo(
			"Person = " + gets(favorites, i) +
			"; Fruit = " + gets(favorites, i + 1) +
			"; Color = " + gets(favorites, i + 2) +
			"; Number = " + (string)geti(favorites, i) + "."
		);
	}
```

With JSON:

```
	// format: name:[fruit,color,number] - 'name' is now a key
	string favorites = jsobject([
		"Bob", jsarray(["apple", "red", 3]),
		"Jane", jsarray(["guava", "fuchsia", 69])
	]);
	// it is more typical to see the above specified as a raw string however -- this is much more memory-efficient:
	string favorites = "{\"Bob\":\["apple\",\"red\",3],\"Jane\":[\"guava\",\"fuchsia\",69]}";
	
	// retrieving a single value:
	string attributes = getjs(favorites, ["Jane"]);
	if(attributes != JSON_INVALID)
		echo("Jane's favorite color is " + getjs(attributes, [1]));
	else
		echo("Jane doesn't exist!");
	
	// iterating over all:
	list names = jskeys(favorites);
	integer i = count(names);
	while(i--)
		string name = gets(names, i);
		string attributes = getjs(favorites, [name]);
		echo(
			"Person = " + name +
			"; Fruit = " + getjs(attributes, [0]) +
			"; Color = " + getjs(attributes, [1]) +
			"; Number = " + getjs(attributes, [2]) + "."
		);
	}
```

Fully familiarizing yourself with the JSON manipulation syntax takes a bit of time but will greatly increase the amount of material you can cram into a script, and is strongly recommended when working with anything in LinksetData storage.

4. If you simply need to iterate over a list of items, most `for` loops can be implemented as `while` loops instead:  

```
integer a = 0;  
integer b = 10;  
for(a = 0; a < b; ++a) {  
	llOwnerSay((string)a); // prints 0 through 9  
}
```   

becomes:

```
integer a = 10;  
while(a--) {  
	llOwnerSay((string)a); // prints 9 through 0  
}
```

This comes with the slight drawback that the index always counts downward—it isn't as thrifty if you rephrase it to count upward—but if you are removing items from a collection, this is the optimal visiting order anyway (as the list is never reindexed due to deleted entries.)

# Convenience Macros

LSL's verbose function names are an unusual fossil of a very narrow time period in the history of software development. Around the turn of the millennium, camel case, type prefixes, vendor prefixes, and verbose, descriptive names were all simultaneously in vogue. Likely the direct inspiration for LSL's function naming convention is the `ns` ("netscape") prefix used by Mozilla, though the confusingly similar `NS` ("NEXTSTEP") prefix still used by Apple may have also contributed.

Needless to say, these are *awful*, and they are also deeply inappropriate—prefixes should be used for libraries, not language built-ins\! Simple operations like C's strlen() become `llGetStringLength()`, requiring more than triple the number of keystrokes to type. Compounding this, the viewer's built-in LSL editor has never had any sort of autocompletion functionality. Given that the average LSL script has room for at most a dozen user functions, the end result is a deeply unsuitable, faddish design choice that has haunted and impeded language adoption for more than twenty years. (Tragically, much of this lives on in the Lua-for-SL library. `llRegionSayTo()` is now `ll.RegionSayTo()`.)

Fortunately there is a band-aid we can slap over this mess in the form of preprocessor macros. These aliases act as nicknames for existing functions and are resolved at runtime.

To use the NS macros, add:

```
#include <utils.lsl>  
#include <objects.lsl>
```

to the top of your script, and make sure these files are in your Firestorm preprocessor's \#includes directory:

[https://github.com/rhetorica/ARES-SDK/blob/main/utils.lsl](https://github.com/rhetorica/ARES-SDK/blob/main/utils.lsl)  
[https://github.com/rhetorica/ARES-SDK/blob/main/objects.lsl](https://github.com/rhetorica/ARES-SDK/blob/main/objects.lsl)

Some highlights are:

| NS macro | LSL function |
| :---- | :---- |
| `index` | `llListFindList` |
| `strlen` | `llStringLength` |
| `substr` | `llGetSubString` |
| `strpos` | `llSubStringIndex` |
| `strdelete` | `llDeleteSubString` |
| `count` | `llGetListLength` |
| `geti` | `llList2Integer` |
| `gets` | `llList2String` |
| `getk` | `llList2Key` |
| `getv` | `llList2Vector` |
| `getr` | `llList2Rot` |
| `getf` | `llList2Float` |
| `sublist` | `llList2List` |
| `alter` | `llListReplaceList` |
| `getjs` | `llJsonGetValue` |
| `setjs` | `llJsonSetValue` |
| `etype` | `llGetListEntryType` |
| `jstype` | `llJsonValueType` |
| `echo` | `llOwnerSay` |
| `tell` | `llRegionSayTo` |
| `js2list` | `llJson2List` |
| `jsarray` | `llList2JSON(JSON_ARRAY, ...)` |
| `jsobject` | `llList2JSON(JSON_OBJECT, ...)` |
| `linked` | `llMessageLinked` |
| `split` | `llParseString2List` for one separator |
| `splitnulls` | `llParseStringKeepNulls` for one separator |
| `concat` | `llDumpList2String` (worst name award) |
| `delrange` | `llDeleteSubList` |
| `delitem` | `llDeleteSubList` for one item |
| `insert` | `llListInsertList` |
| `shuffle` | `llListRandomize` |
| `replace` | `llReplaceSubString` |
| `NOWHERE` | `0xFFFFFFFF` (for invalid indices; uses less bytecode than \-1) |
| `LAST` | `0xFFFFFFFF` (for getting the last item in a list; less bytecode than \-1) |
| `setp` | `llSetLinkPrimitiveParamsFast` |
| `getp` | `llGetLinkPrimitiveParams` |
| `geto` | `llGetObjectDetails` |
| `ZR` | `ZERO_ROTATION` |
| `ZV` | `ZERO_VECTOR` |
| `ONES` | `<1, 1, 1>` |

Both utils.lsl and objects.lsl include numerous convenience functions besides the simple macros listed here, especially list manipulation functions. If you are reviewing NS source code and don't recognize a symbol, chances are good that it is defined in one of these two files.

# Routed Message Dispatch

The standard mechanism for inter-script communication is `llMessageLinked()` and `link_message`. This has a hidden flaw which is not immediately apparent in toy examples: link messages are multicast, and are received by *all* scripts in the target link. If the source and target prim are the same, then even the sender receives the message, provided it has a `link_message` event of its own. Occasionally this behavior is desirable, but for any project containing a number of scripts equal to N in the same prim, the spurious script activations quickly become immense. Consider:

	Script 1 sends "`ping`" to all other components
	Scripts 1..N receive the "`ping`" message and reply "`pong`"
	Script 1 receives N "`pong`" messages as intended, including one from itself
	Script 2 receives N "`pong`" messages that it must ignore
	Script 3 receives N "`pong`" messages that it must ignore
	...  
	Script N receives N "`pong`" messages that it must ignore

This is how a denial-of-service amplification attack works, except the victim in this case is the language runtime\!

The traditional solution to this design flaw is to put scripts in separate primitives, which adds considerable overhead to product updates and is seldom followed completely. Even if the programmer identifies which script pairs communicate and takes care to separate them into a multipartite graph, crosstalk still occurs among neighbors. Something along these lines was attempted in OpenCollar 6.0 (a number chosen because there were six different groups of scripts in various links), which was eventually rebranded Peanut No. 9\. Unfortunately this still suffers greatly from added maintenance complexity and activation overhead (a link containing N scripts will always generate N events from one incoming message.)

The routed dispatch approach rejects link messages entirely in favor of llRegionSayTo(). If script A wants to send the text "message" to script B, it does the following:

1. Script A sends "B message" to the dispatcher prim  
2. The dispatcher script looks up B in a table of known client scripts  
3. The dispatcher sends message to Script B on its registered channel

This has some overhead—two events must be handled in sequence instead of one—but because each client script can listen on a unique channel, script A and B can be colocated without any crosstalk whatsoever. In ARES, the dispatcher is called the kernel, which is named Psyche; Psyche is also used in the AHM (DSA) client.

To add multicast messages to this model, additional strategies are required: clients register their interest in handling certain multicast signals with a repeater script, which then amplifies the signal when it is actually triggered. In ARES, these are called events, and the repeater script is a daemon called `_scheduler`.

Messages need not be prefixed with a script's entire name; in practice it is often wiser to use some fixed-length encoding representing a job number or similar. ARES uses a custom base 64 encoding with a two-byte field to represent a PID in the range 0-4095, which programs are assigned during initial registration. These PIDs also form the basis of the channel on which each client script receives incoming messages.
