
#ifndef UTILS
#define UTILS

/*

   ***********************************************************
   *                                                         *
   *    NANITE SYSTEMS ADVANCED TACTICAL OPERATING SYSTEM    *
   *                                                         *
   *                     UTILS COMPONENT                     *
   *                                                         *
   *  Copyright, (C) Nanite Systems Corp., 1984-85, 2017-25  *
   *                                                         *
   *     Copyright, (C) University of Michigan 1977-1981     *
   *                                                         *
   ***********************************************************
   
   THE SOURCE CODE FOR THIS LIBRARY COMPONENT IS PROVIDED TO
   NANITE SYSTEMS CUSTOMERS FOR DEVELOPMENT OF COMPATIBLE
   SOFTWARE.
   
   BY USING THIS CODE, YOU AGREE NOT TO MODIFY OR DISTRIBUTE
   IT FOR COMMERCIAL GAIN, EXCEPT IN A COMPILED PRODUCT. YOU
   MAY PROVIDE THE SOURCE CODE OF THIS FILE FOR FREE OR
   INCLUDED WITH YOUR OWN DEVELOPMENT PACKAGE AS LONG AS THIS
   NOTICE IS INCLUDED AND THE REST OF THE FILE IS UNMODIFIED.
   
   INTERACTIONS WITH OTHER COMPONENTS OF THE OPERATING SYSTEM
   ARE SUBJECT TO THE APPROPRIATE END-USER LICENSE AGREEMENT
   (EULA).
   
   IDV:				F0960303D0002
   VENDOR DUNS:     005128988
   
*/

// integer contains(list haystack, any needle): returns a non-zero value if needle is in haystack; otherwise 0. This macro cannot handle list literals, so wrap them in (parens)
#define contains(_haystack, _needle) ~llListFindList(_haystack, (list)(_needle))

// integer index(list haystack, any needle): returns the index of needle's first occurrence if it is in haystack; otherwise -1. This macro cannot handle list literals, so wrap them in (parens)
#define index(_haystack, _needle) llListFindList(_haystack, (list)(_needle))


// integer strlen(string s): returns the length of the specified string in characters; see also strlen_byte()
#define strlen llStringLength

// string substr(string s, integer x, integer y): returns a contiguous substring of the specified string, starting from position x and ending at position y, inclusive of both end-points; negative indices count from the end of the string
#define substr(_haystack, _start, _end) llGetSubString(_haystack, _start, _end)

// integer strpos(string haystack, string needle): returns the index of needle's first occurrence if it is in haystack; otherwise -1
#define strpos(_haystack, _needle) llSubStringIndex(_haystack, _needle)

// string strdelete(string s, integer x, integer y): returns a copy of a string with the subrange [x, y] removed, inclusive of both endpoints; negative indices count from the end of the string
#define strdelete llDeleteSubString

// string delstring(string s, integer x, integer y): returns a copy of a string with the subrange [x, y] removed, inclusive of both endpoints; negative indices count from the end of the string
#define delstring llDeleteSubString


// integer ucount(list x): returns TRUE if x is non-empty
#define ucount(...) (__VA_ARGS__ != [])

// integer count(list x): returns the number of elements in x
#define count llGetListLength


// integer geti(list x, integer n): returns the value of an integer element at position n in list x, or 0 if element n is not an integer; negative indices count from the end of the list
#define geti llList2Integer

// string gets(list x, integer n): returns the value of a string (or key) element at position n in list x, or "" if element n is not a string (or key); negative indices count from the end of the list
#define gets llList2String

// key getk(list x, integer n): returns the value of a key (or string) element at position n in list x, or "" if element n is not a key (or string); negative indices count from the end of the list
#define getk llList2Key

// vector getv(list x, integer n): returns the value of a vector element at position n in list x, or ZERO_VECTOR if element n is not a vector; negative indices count from the end of the list
#define getv llList2Vector

// rotation getr(list x, integer n): returns the value of a rotation element at position n in list x, or ZERO_ROTATION if element n is not a rotation; negative indices count from the end of the list
#define getr llList2Rot

// float getf(list x, integer n): returns the value of a float element at position n in list x, or 0.0 if element n is not a float; negative indices count from the end of the list
#define getf llList2Float


// list sublist(list b, integer x, integer y): returns a new list containing the elements of list b, from the subrange [x, y], inclusive of both endpoints
#define sublist llList2List


// list alter(list haystack, list needle, integer x, integer y): returns a new list containing the elements of list haystack prior to position x, followed by the elements of list needle, and then the elements of list haystack after list y, thereby replacing the range [x, y] in list haystack (inclusive) with the contents of list needle; negative indices count from the end of list haystack
#define alter llListReplaceList

// string getjs(string json, list subscripts): extracts a fragment of JSON from a larger JSON string by following the specified subscripts. Atomic strings are returned unquoted. An empty subscript list returns the entire string json, unaltered. If the subscripts do not address an extant element, JSON_INVALID is returned. JSON objects must be indexed by string and JSON arrays must be indexed by integers.
#define getjs llJsonGetValue

// string setjs(string json, list subscripts, string value): returns a copy of string json with an element substituted. The element to substitute must be specified by the provided subscripts. Subscripts can be used to force the creation of new elements, either by appending string subscripts (to create nested objects) or through the use of the special JSON_APPEND subscript value to add to the end of an array. Values are interpreted as JSON first, numbers second, and strings third, so "1.0" will become a number, but "[1.0]" will become an array containing a number. The special value JSON_DELETE can be used to remove an element, and the values JSON_TRUE and JSON_FALSE are used to store booleans. You should sanitize your input to prevent storing the characters [, ], {, or } in string values, as the JSON parser is incomplete and will interpret these as evidence of corruption even when other implementations accept them. Always check the return value for JSON_INVALID, as this is evidence of an unsuccessful operation and will occur even when trying to JSON_DELETE an element that does not exist--otherwise you will lose data.
#define setjs llJsonSetValue

// integer etype(list x, integer n): returns a numeric constant describing the type of the element at position n in list x. Possible return values are TYPE_INVALID, TYPE_INTEGER, TYPE_FLOAT, TYPE_STRING, TYPE_KEY, TYPE_VECTOR, and TYPE_ROTATION (0-6).
#define etype llGetListEntryType

// string jstype(string json, list subscripts): as getjs(), but returns the type of an element instead of its actual value. Possible return values are JSON_INVALID, JSON_OBJECT, JSON_ARRAY, JSON_NUMBER, JSON_STRING, JSON_NULL, JSON_TRUE, and JSON_FALSE (U+FDD0 through UFDD7).
#define jstype llJsonValueType

// echo(string message): sends a string directly to the owning agent's viewer; equivalent to llOwnerSay(). Maximum limit is 1024 bytes.
#define echo llOwnerSay

// tell(key id, integer c, string message): sends a string to the specified object id on channel c. If id is an avatar, all attachments will receive it. If id is the root of a linkset, all links will receive it. Maximum limit for message is 256 bytes if c is negative, otherwise 1024 bytes.
#define tell llRegionSayTo


// string list2js(string type, list x): returns a string that is a representation of the values in list x as encoded into the specified type (which must be one of JSON_OBJECT or JSON_ARRAY). All types other than integers and floats will be converted into quoted strings, but strings that resemble JSON (due to starting and ending with [] or {}) will be interpreted as JSON. If converting into JSON_OBJECT, the source list will be interpreted as having a stride of 2, with even-numbered elements becoming the keys of the new object, and odd-numbered elements becoming values.
#define list2js llList2Json

// list js2list(string json): returns a list that contains every element of the original JSON object or array atomized. Nested values are left as strings. Vectors, rotations, and keys previously converted into strings by list2js() are left as strings. Objects are converted into lists with a stride of 2, where even-numbered elements are the original JSON's keys and odd-numbered elements are their corresponding values.
#define js2list llJson2List

// string jsarray(list x): returns a JSON string containing the elements of list x. All types other than integers and floats will be converted into quoted strings, but strings that resemble JSON (due to starting and ending with [] or {}) will be interpreted as JSON.
#define jsarray(...) llList2Json(JSON_ARRAY, (list)(__VA_ARGS__))

// string jsobject(list x): returns a string that is a representation of the values in list x encoded into a JSON object. The source list will be interpreted as having a stride of 2, with even-numbered elements becoming the keys of the new object, and odd-numbered elements becoming values. For values, all types other than integers and floats will be converted into quoted strings, but strings that resemble JSON (due to starting and ending with [] or {}) will be interpreted as JSON.
#define jsobject(...) llList2Json(JSON_OBJECT, (list)(__VA_ARGS__))

// list jskeys(string json): returns a list containing only the key names of the provided JSON object. Will misbehave if fed a JSON array by accident. Equivalent to Object.keys(obj) in Javascript.
#define jskeys(__jso) llList2ListStrided(llJson2List(__jso), 0, LAST, 2)


// list jsvalues(string json): returns a list containing only the values of the provided JSON object. Will misbehave if fed a JSON array by accident. Equivalent to Object.values(obj) in Javascript.
#define jsvalues(__jso) llList2ListStrided(llDeleteSubList(llJson2List(__jso), 0, 0), 0, LAST, 2)


// linked(integer t, integer n, string m, key id): sends a link_message() event to linked prim t, with the parameters n, m, and id. Be careful when using link_message() for complex applications, as it can not only run out of event queue space (~64 events can be queued before silent dropping occurs), but also trigger an immense amount of pointless LSL executions (64 messages received by 64 scripts = 4096 events) that severely impact sim performance. For a tight, script-to-script communication method, use llListen() with the UUID set, as this filtering is done outside LSL.
#define linked llMessageLinked


// list split(string haystack, string sep): returns the fragments of a string haystack split at instances of a single separator string, sep. Consecutive separators will be merged.
#define split(_haystack, _needle) llParseString2List(_haystack, (list)(_needle), [])

// list splitnulls(string haystack, string sep): returns the fragments of a string haystack split at instances of a single separator string, sep. Consecutive separators will result in empty elements.
#define splitnulls(_haystack, _needle) llParseStringKeepNulls(_haystack, (list)(_needle), [])

// string concat(list x, string sep): returns a concatenated form of the elements of list x, inserting string sep between each pair of elements.
#define concat llDumpList2String

// list delrange(list b, integer x, integer y): returns a copy of a list with the subrange [x, y] removed, inclusive of both endpoints; negative indices count from the end of the list
#define delrange llDeleteSubList

// list delitem(list b, integer n): returns a copy of a list with the element at position n removed; negative indices count from the end of the list. This macro cannot handle list literals, so wrap them in (parens)
#define delitem(_haystack, _index) llDeleteSubList(_haystack, _index, _index)

// list insert(list a, list b, integer n): returns a copy of list a with the contents of list b inserted before element n; to append to the end of a list, use: a + b
#define insert llListInsertList
// list shuffle(list x): returns the list with its elements in random order
#define shuffle llListRandomize

// string replace(string haystack, string needle, string replacement): returns a copy of haystack with all instances of needle replaced by replacement
#define replace(_haystack, _old, _new) llReplaceSubString(_haystack, _old, _new, 0)


// string vec2str(vector v): returns a string "x y z" from a vector <x, y, z>; argument must be a variable name, not a literal, see also vec2str2() which is slower but does not have this restriction
#define vec2str(_vec) ((string)_vec.x + " " + (string)_vec.y + " " + (string)_vec.z)

// string vec2str2(vector v): returns a string "x y z" from a vector <x, y, z>; argument may be a literal, but generated code is worse than vec2str()
#define vec2str2(_vec) substr(replace((string)(_vec), ", ", " "), 1, -2)

// vector str2vec(string v): returns a vector <x, y, z> from a string that describes a vector in the format "x y z".
#define str2vec(__str) (vector)("<" + replace(__str, " ", ",") + ">")

// "Nothing is true - all is permissible."
//     - Hassan i Sabbah


// string format_percentage(float f): converts a float to a percentage, e.g. 0.5 to 50%, or -2.31 to -231%. Always returns an integer.
#define format_percentage(xxx) ((string)((integer)((xxx) * 100)) + "%")

// string format_float(float f, integer places): truncates a float to the specified precision after the decimal point, e.g. format_float(0.010999, 3) == "0.010"; always rounds toward 0
#define format_float(_number, _places) llGetSubString( (string) (_number), 0, llSubStringIndex( (string) (_number), ".") + _places )


// list list_union(list x, list y): returns a list containing the elements of list x, followed by any elements of list y that did not appear in list x
list list_union(list ly, list lx) { /* add the lists, eliminating duplicates */
    list lz = [];
	integer x = count(ly);
	
    while(x--)
        if(!~llListFindList(lx, sublist(ly, x, x)))
            lz = sublist(ly, x, x) + lz;
	
    return lx + lz;
}

// list list_exclude(list x, list y): returns a list containing the elements of list x that did not appear in list y
list list_exclude(list ly, list lx) { /* remove entries in second list from first */
	list lz = [];
	integer x = count(ly);
	
    while(x--)
        if(!~llListFindList(lx, sublist(ly, x, x)))
            lz = sublist(ly, x, x) + lz;
	
    return lz;
}

// list list_intersect(list x, list y): returns a list containing the elements from list x that are also in list y; if x contains duplicates, these will be preserved
list list_intersect(list ly, list lx) { /* remove entries not in both lists */
	list lz = [];
	integer x = count(ly);
	
    while(x--)
        if(~llListFindList(lx, sublist(ly, x, x)))
            lz = sublist(ly, x, x) + lz;
	
    return lz;
}

// list list_unique(list x): returns a list containing only the unique elements of list x; if x contains duplicates, these will appear only at their first position
list list_unique(list lx) { /* remove duplicates */
	integer x = count(lx);
	while(x--)
		if(llListFindList(lx, sublist(lx, x, x)) != x)
			lx = delitem(lx, x);
	
	return lx;
}


// float sum(list x): returns the total sum of all numeric elements in the list
#define sum(...) llListStatistics(LIST_STAT_SUM, __VA_ARGS__)

// float sum_sq(list x): returns the total sum of all numeric elements in the list, squaring each one first
#define sum_sq(...) llListStatistics(LIST_STAT_SUM_SQUARES, __VA_ARGS__)

// float mean(list x): returns the average of all numeric elements in the list
#define mean(...) llListStatistics(LIST_STAT_MEAN, __VA_ARGS__)

// float min(list x): returns the lowest of all numeric elements in the list
#define min(...) llListStatistics(LIST_STAT_MIN, __VA_ARGS__)

// float max(list x): returns the highest of all numeric elements in the list
#define max(...) llListStatistics(LIST_STAT_MAX, __VA_ARGS__)

// float median(list x): returns the median (middle value) of all numeric elements in the list; if the number of numeric elements is even, returns the average of those two
#define median(...) llListStatistics(LIST_STAT_MEDIAN, __VA_ARGS__)

// float range(list x): returns the difference between the lowest and highest of the numeric elements in the list
#define range(...) llListStatistics(LIST_STAT_RANGE, __VA_ARGS__)

// float std_dev(list x): calculates the average of all numeric elements in the list, then the squared differences between each numeric element and that average, then returns the square root of the average of these squared differences
#define std_dev(...) llListStatistics(LIST_STAT_STD_DEV, __VA_ARGS__)

// float geom_mean(list x): returns the product of all the numeric elements in the list, raised to the power 1/n, where n is the number of numeric elements in the list
#define geom_mean(...) llListStatistics(LIST_STAT_GEOMETRIC_MEAN, __VA_ARGS__)

// float countn(list x): returns the number of numeric elements in the list
#define countn(...) llListStatistics(LIST_STAT_NUM_COUNT, __VA_ARGS__)


// integer validate_key(key k): returns TRUE if k is a valid UUID, otherwise FALSE
integer validate_key(key k) { /* slow, but correct */
	string sk = llToLower((string)k);
	return (
		strlen(sk) == 36
		&& !count(split((string)llParseString2List((string)llParseString2List(sk, ["0","1","2","3","4","5","6","7"], []), ["8", "9", "a", "b", "c", "d", "e", "f"], []), "-")) /* llParseString2List can't handle more than 8 separators */
		&& count(splitnulls(sk, "-")) == 5
		&& (substr(sk, 8, 8) + substr(sk, 13, 13) + substr(sk, 18, 18) + substr(sk, 23, 23)) == "----"
	);
}

// list remap(list old, list new, list input): iterates over input, translating its elements from the old list to the new list, assuming the elements of old and new correspond in indices; e.g. remap(["red", "green", "blue"], ["cyan", "magenta", "yellow"], ["blue", "blue", "green"]) ==> ["yellow", "yellow", "magenta"]
list remap(list keys, list values, list input) {
	list results;
	integer i = count(input);
	while(i--) {
		integer j = llListFindList(keys, sublist(input, i, i));
		if(~j)
			results = sublist(values, j, j) + results;
	}
	
	return results;
}

// list zip(list A, list B): creates a strided list from two input lists; excess elements are discarded
list zip(list A, list B) {
	list out;
	integer limit = count(A);
	integer Blen = count(B);
	if(Blen < limit)
		limit = Blen;
	
	integer i = 0;
	while(i < limit) {
		out += sublist(A, i, i) + sublist(B, i, i);
		++i;
	}
	
	return out;
}

// string format_table(list A, integer stride, string separator): prints a strided list as CSV/TSV
string format_table(list A, integer stride, string separator) {
	if(separator == "")
		separator = ",";
	
	integer i = 0;
	integer imax = count(A);
	string out;
	for(i = 0; i < imax; ++i) {
		if(i % stride == 0 && i != 0)
			out += "\n";
		else if(i % stride)
			out += separator;
		out += (string)sublist(A, i, i);
	}
	return out;
}


/* unicode management functions */

// string strleft_byte(string s, integer b): returns a string containing characters from the start of s, so long as they take up no more than b bytes. Fragmented characters are discarded.
string strleft_byte(string str, integer bytes) {
    string temp = llStringToBase64(str);
    if(strlen(temp) <= (bytes * 8) / 6)
        return str;
    temp = llBase64ToString(substr(temp+"==", (bytes * -2) % 3, (bytes * 4 - 1) / 3));
    integer i = strlen(temp) - 1;
    if(substr(temp, i, i) != substr(str, i, i))
        return delstring(temp, i, i); /* last char was multi-byte and was truncated */
    return temp;
}

// integer strlen_byte(string s): returns the length of the provided Unicode string in bytes rather than characters (as strlen() would)
integer strlen_byte(string str) {
	return (( (3 * strpos(llStringToBase64(str)+"=", str = "=")) >> 2 ));
}

// integer strlen_byte_inline(string s): returns the length of the provided Unicode string in bytes rather than characters (as strlen() would) - inline macro version of the strlen_byte() function
#define strlen_byte_inline(str) (( (3 * strpos(llStringToBase64(str)+"=", "=")) >> 2 ))


// string format_time(float number): returns "x days, hh:NN:SS" format for a number of provided seconds, leaving off days or hours for smaller values; negative values are presented wrapped in -()
string format_time(float number) {
	integer negative;
	if(number < 0) {
		negative = TRUE;
		number = llFabs(number);
	}
    string output;

	number += 0.5;
	
    integer secs = (integer)(number) % 60;
    integer minutes = (integer)(number / 60) % 60;
    integer hours = (integer)(number / 3600) % 24;
    integer days = (integer)(number / 86400);
    
    if(days == 1)
		output = "1 day, ";
    else if(days)
		output = (string)days + " days, ";
    
    // if(hours > 0 || days > 0)
	output += (string)hours + ":";
    
    if(minutes < 10)
		output += "0";
	
    output += (string)minutes + ":";
    
    if(secs < 10)
		output += "0";
		
    output += (string)secs;
	
	if(negative)
		output = "-(" + output + ")";
	
    return output;
}


// string hex(integer n): converts an integer to lower-case hexadecimal using as few characters as possible; no prefix or suffix is appended
string hex(integer bits) {
    string nybbles = "";
    do {
        integer lsn = bits & 0xF; // least significant nybble
        nybbles = substr("0123456789abcdef", lsn, lsn) + nybbles;
    } while (bits = (0xfffFFFF & (bits >> 4)));
    return nybbles;
}

/* from http://wiki.secondlife.com/wiki/Efficient_Hex */

// various semantic negative one replacements:

// NOWHERE: use this to represent -1 when it indicates an element is not present, e.g. strpos("x", "y") == NOWHERE
#define NOWHERE 0xFFFFFFFF

// LAST: use this to represent -1 when it indicates the last position in a string or list, e.g. substr(s, 0, LAST) == s
#define LAST 0xFFFFFFFF

// SAFE_EOF: a string encoding of U+0004 (the ASCII EOF control code), used as an in-band record separator in some protocols, especially Refactor Robotics Aurora. Some preprocessors do not like seeing literal ASCII control codes. ARES redefines this as U+007F (ASCII DEL), which has much better support and will not cause deserialization failures if it is stored on the heap during a sim transfer.
#define SAFE_EOF llChar(4)

// SOUND_DEFAULT: a placeholder sound, meant to complement SL's TEXTURE_DEFAULT
#define SOUND_DEFAULT "f1adc36c-4c3f-081b-4ab2-fa5105d80561"

#endif // UTILS
