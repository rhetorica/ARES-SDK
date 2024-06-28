#ifndef GLOB_MATCH
#define GLOB_MATCH

// ported by rhetorica 2024-06-25
// from https://github.com/torvalds/linux/blob/master/lib/glob.c

// License: Dual MIT/GPL

/**
 * glob_match - Shell-style pattern matching, like !fnmatch(pat, str, 0)
 * @pat: Shell-style pattern to match, e.g. "*.[ch]".
 * @str: String to match.  The pattern must match the entire string.
 *
 * Perform shell-style glob matching, returning true (1) if the match
 * succeeds, or false (0) if it fails.  Equivalent to !fnmatch(@pat, @str, 0).
 *
 * Pattern metacharacters are ?, *, [ and \.
 * (And, inside character classes, !, - and ].)
 *
 * This is small and simple implementation intended for device blacklists
 * where a string is matched against a number of patterns.  Thus, it
 * does not preprocess the patterns.  It is non-recursive, and run-time
 * is at most quadratic: strlen(@str)*strlen(@pat).
 *
 * An example of the worst case is glob_match("*aaaaa", "aaaaaaaaaa");
 * it takes 6 passes over the pattern before matching the string.
 *
 * Like !fnmatch(@pat, @str, 0) and unlike the shell, this does NOT
 * treat / or leading . specially; it isn't actually used for pathnames.
 *
 * Note that according to glob(7) (and unlike bash), character classes
 * are complemented by a leading !; this does not support the regex-style
 * [^a-z] syntax.
 *
 * An opening bracket without a matching close is matched literally.
 */

#ifdef DEBUG_GLOB
integer last_c;
integer last_d;
integer last_str_i;
integer last_pat_i;
#endif
 
// bool __pure glob_match(char const *pat, char const *str)
integer glob_match(string pat, string str)
{
	/*
	 * Backtrack to previous * on mismatch and retry starting one
	 * character later in the string.  Because * matches all characters
	 * (no exception for /), it can be easily proved that there's
	 * never a need to backtrack multiple levels.
	 */
	
	// char const *back_pat = NULL, *back_str;
	integer back_pat = NOWHERE;
	integer back_str;
	
	/*
	 * Loop over each token (character or class) in pat, matching
	 * it against the remaining unmatched tail of str.  Return false
	 * on mismatch, or true after matching the trailing nul bytes.
	 */
	//for (;;) {
	
	integer str_i;
	integer pat_i;
		
	while (TRUE) {
		// unsigned char c = *str++;
		// unsigned char d = *pat++;
		
		integer c = llOrd(str, str_i++);
		integer d = llOrd(pat, pat_i++);
		
		#ifdef DEBUG_GLOB
		echo((string)c + ", " + (string)d + ", " + (string)str_i + ", " + (string)pat_i);
		
		if(c == last_c && d == last_d && str_i == last_str_i && pat_i == last_pat_i)
			return 2 / 0;
		#endif
		
		// switch (d) {
		// case '?':	/* Wildcard: anything but nul */
		if(d == 0x3f) { // '?'
			if (c == 0x00) // EOL
				// return false;
				return FALSE;
			//break;
			jump skip_default;
		// case '*':	/* Any-length wildcard */
		} else if(d == 0x2a) { // '*'
			// if (*pat == '\0')	/* Optimize trailing * case */
			if(llOrd(pat, pat_i) == 0x00)
				// return true;
				return TRUE;
			//back_pat = pat;
			back_pat = pat_i;
			//back_str = --str;	/* Allow zero-length match */
			back_str = --str_i;
			// break;
			jump skip_default;
		// case '[': {	/* Character class */
		} else if(d == 0x5b) { // '['
			//bool match = false, inverted = (*pat == '!');
			integer match = FALSE;
			integer inverted = (llOrd(pat, pat_i) == 0x21); // '!'
			//char const *class = pat + inverted;
			integer class_i = pat_i + inverted;
			//unsigned char a = *class++;
			integer a = llOrd(pat, class_i++);

			/*
			 * Iterate over each span in the character class.
			 * A span is either a single character a, or a
			 * range a-b.  The first span may begin with ']'.
			 */
			do {
				// unsigned char b = a;
				integer b = a;

				//if (a == '\0')	/* Malformed */
				if(a == 0x00)
					// goto literal;
					jump literal; // FIXME

				//if (class[0] == '-' && class[1] != ']') {
				if(llOrd(pat, class_i + 0) == 0x2d && llOrd(pat, class_i + 1) != 0x5d) {
					// b = class[1];
					b = llOrd(pat, class_i + 1);

					//if (b == '\0')
					if(b == 0x00)
						// goto literal;
						jump literal;

					// class += 2;
					class_i += 2;
					/* Any special action if a > b? */
				}
				// match |= (a <= c && c <= b);
				match = match | (a <= c && c <= b);
			// } while ((a = *class++) != ']');
			} while((a = llOrd(pat, class_i++)) != 0x5d);

			if (match == inverted)
				jump backtrack;
				// goto backtrack;
			//pat = class;
			pat_i = class_i;
			// } // <-- unnecessary
			// break;
			jump skip_default;
		// case '\\':
		} else if(d == 0x5c) { // '\\'
			// d = *pat++;
			d = llOrd(pat, pat_i++);
			// fallthrough;
		}
		//default:	/* Literal character */
//literal:
		@literal;
			if (c == d) {
				//if (d == '\0')
				if(d == 0x00)
					//return true;
					return TRUE;
				//break;
				jump skip_default;
			}
//backtrack:
		@backtrack;
			//if (c == '\0' || !back_pat)
			if(c == 0x00 || !~back_pat)
				//return false;	/* No point continuing */
				return FALSE;
			/* Try again from last *, one character later in str. */
			//pat = back_pat;
			pat_i = back_pat;
			//str = ++back_str;
			str_i = ++back_str;
			//break;
			jump skip_default;
		//}
		@skip_default;
		#ifdef DEBUG_GLOB
		last_d = d;
		last_c = c;
		last_str_i = str_i;
		last_pat_i = pat_i;
		#endif
	}
	return FALSE; // unreachable
}

#endif // GLOB_MATCH
