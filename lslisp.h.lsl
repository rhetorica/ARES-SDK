
// LSLisp Meta

// Implementation for finding number of occurrences of a substring
// (Note that the inline version can take a string or a list)

#ifdef INLINE_OCCUR
	#define occur(haystack, needle) (count(splitnulls((string)(haystack), (needle))) - 1)
#else
	integer occur(list haystack, string needle) {
		return (count(splitnulls((string)(haystack), (needle))) - 1);
	}
#endif

#define tokenize(str) llParseStringKeepNulls(str, [" "], ["(", ")", "\""])

// LSLisp Constants

#ifndef LISP_EXECUTE_FILE
	#define LISP_EXECUTE_FILE 860
#endif

#ifndef LISP_EXECUTE_FUNC
	#define LISP_EXECUTE_FUNC 861
#endif
