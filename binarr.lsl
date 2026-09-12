
#ifndef BINARR_H_
#define BINARR_H_

/*

   ***********************************************************
   *                                                         *
   *       TIGHTLY-PACKED BINARY ARRAY IMPLEMENTATION        *
   *                                                         *
   *     Copyright, (C) Nanite Systems Corp., 2022, 2026     *
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

#include <utils.lsl>

/*
 * Binary Arrays
 *
 * This stores a bitmap (array of booleans) inside a string to save memory.
 * 
 * For encoding safety reasons, values are stored at a density of no more than six
 * booleans per character cell; 000000 is remapped to 0x7f to avoid premature \0 termination;
 * otherwise, data is stored in the bottom six bits of the character cell.
 *
 * The packing rate may be redefined to other values to meet external data alignment requirements.
 *
 * The binary array datatype keyword is 'binarr' (syntactic sugar for 'string')
 *
 * Provided functions and macros:
 *
 * binarr: synonym for 'string' type definition keyword
 * ba_count(A): number of cells in binary array A (always a multiple of BA_PACK_RATE)
 * ba_null_char: 0x7f, indicating no values are stored in a cell
 * ba_create(N): creates a binary array large enough to hold N values
 * ba_set(A, I, V): sets A[I] = V
 * ba_get(A, I): gets A[I]
 * ba_find_free(A): returns index of first 0 in A
 * ba_find_free_reverse(A): returns index of last 0 in A
 * ba2str(A): unpacks A into stream of "1" and "0" characters
 * str2ba(s): reverses ba2str; any non-"1" characters are treated as 0
 *
 */

#ifndef BA_PACK_RATE
	#define BA_PACK_RATE 6
#endif

#if BA_PACK_RATE == 7
	// not usable, since 0x0 must be remapped to a value < 0x80
	#define BA_BLACKOUT 0x7f
	#define BA_EMPTY "0000000"
	#define BA_FULL "1111111"
#elif BA_PACK_RATE == 6
	#define BA_BLACKOUT 0x3f
	#define BA_EMPTY "000000"
	#define BA_FULL "111111"
#elif BA_PACK_RATE == 5
	#define BA_BLACKOUT 0x1f
	#define BA_EMPTY "00000"
	#define BA_FULL "11111"
#elif BA_PACK_RATE == 4
	#define BA_BLACKOUT 0x0f
	#define BA_EMPTY "0000"
	#define BA_FULL "1111"
#endif

#define binarr string
#define ba_count(__v) (BA_PACK_RATE * strlen_byte(__v))
#define ba_null_char 0x7f

#if (ba_null_char == BA_BLACKOUT) || !defined(BA_BLACKOUT)
	#error "Unsupported BA_PACK_RATE"
#endif

binarr ba_create(integer len) {
	binarr new = llChar(ba_null_char);
	integer rem = len % BA_PACK_RATE;
	if(rem)
		len = len + BA_PACK_RATE - rem;
	
	integer half_len = len >> 1;
	while(ba_count(new) < half_len)
		new = new + new;
	if(ba_count(new) < len)
		new = new + substr(new, 0, (integer)llCeil((float)(len - half_len) / BA_PACK_RATE) - 1);
	new = new;
	return new;
}

binarr ba_set(binarr ba, integer i, integer v) {
	v = v & 1;
	integer ci = i / BA_PACK_RATE;
	// echo("Altering character " + ci);
	integer c = llOrd(ba, ci);
	// echo("Was: " + (string)c);
	if(c == ba_null_char)
		c = 0;
	// echo("Really: " + (string)c);
	integer s = i % BA_PACK_RATE;
	// echo("Slot: " + (string)s);
	integer vm = (1 << s);
	// echo("V mask: " + (string)vm);
	if(((c & vm) >> s) == v) {
		// echo("No change");
		return ba; // unmodified
	} else if(v) {
		// echo("Enabled");
		c = c | vm;
	} else {
		// echo("Disabled");
		c = c & ~vm;
	}
	// echo("Result: " + (string)c);
	if(!c) c = ba_null_char;
	// echo("Saving as: " + (string)c);
	return llInsertString(llDeleteSubString(ba, ci, ci), ci, llChar(c));
}

integer ba_get(binarr ba, integer i) {
	integer c = llOrd(ba, i / BA_PACK_RATE);
	if(c == ba_null_char)
		c = 0;
	integer s = i % BA_PACK_RATE;
	return (c >> s) & 1;
}

integer ba_find_free(binarr ba) {
	integer imax = strlen(ba);
	integer i = 0;
	while(i < imax) {
		integer c = llOrd(ba, i);
		if(c == ba_null_char) {
			return i * BA_PACK_RATE;
		} else if(c != BA_BLACKOUT) {
			integer s = 0;
			while(((c & (1 << s)) != 0) && (s < BA_PACK_RATE))
				++s;
			
			if(s < BA_PACK_RATE)
				return s + i * BA_PACK_RATE;
		}
		++i;
	}
	return NOWHERE;
}

integer ba_find_free_reverse(binarr ba) {
	integer imax = strlen(ba);
	integer i = imax;
	do {
		integer c = llOrd(ba, i);
		if(c == ba_null_char) {
			return i * BA_PACK_RATE;
		} else if(c != BA_BLACKOUT) {
			integer s = BA_PACK_RATE;
			while(((c & (1 << s)) != 0) && (s >= 0))
				--s;
			
			if(s >= 0)
				return s + i * BA_PACK_RATE;
		}
	} while(i--);
	
	return NOWHERE;
}

string ba2str(binarr ba) {
	integer imax = strlen(ba);
	integer i = 0;
	string output;
	while(i < imax) {
		integer c = llOrd(ba, i);
		if(c == ba_null_char)
			output += BA_EMPTY;
		else if(c == BA_BLACKOUT)
			output += BA_FULL
		else {
			integer s = 0;
			while(s < BA_PACK_RATE) {
				integer o = (c & (1 << s)) >> s;
				output += (string)o;
				++s;
			}
		}
		++i;
	}
	return output;
}

binarr str2ba(string sa) {
	integer simax = strlen(sa);
	integer si = 0;
	binarr output;
	integer c = 0;
	integer pi = 0;
	integer ci = 0;
	while(si < simax) {
		if(pi == BA_PACK_RATE) {
			if(c == 0) c = ba_null_char;
			output += llChar(c);
			pi = c = 0;
			++ci;
		}
		
		if(llOrd(sa, si) == 0x31) // '1'
			c = c | (1 << pi);
		
		++pi;
		++si;
	}
	
	if(pi > 0) {
		if(c == 0) c = ba_null_char;
		output += llChar(c);
	}
	
	return output;
}

#endif // BINARR_H_
