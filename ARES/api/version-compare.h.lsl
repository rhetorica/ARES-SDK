
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  VERSION-COMPARE.H.LSL
 *
 *  This program is covered under the terms of the ARES Software Copyright
 *  License, Section 3 (ASCL-iii). It may be redistributed or used as the
 *  basis of commercial, closed-source products so long as steps are taken
 *  to ensure proper attribution as defined in the text of the license.
 *  
 *  To see the full text of the ASCL, type 'help license' on any standard
 *  ARES distribution, or visit http://nanite-systems.com/ASCL for the
 *  current version.
 *
 *  DISCLAIMER
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS
 *  IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 *  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.
 *
 *  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 *  DAMAGES HOWEVER CAUSED ON ANY THEORY OF LIABILITY ARISING IN ANY WAY OUT
 *  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 *  DAMAGE.
 *
 * =========================================================================
 *
 */

#ifndef _ARES_VERSION_COMPARE_H_
#define _ARES_VERSION_COMPARE_H_

// compares two version numbers
// returns a negative number if the first argument is greater
// returns a positive number if the second argument is greater
// returns zero if they are equal

integer version_compare(string version_a, string version_b) {
	if(version_a == version_b)
		return 0;
	
	list pa = splitnulls(version_a, ".");
	list pb = splitnulls(version_b, ".");
	integer ca;
	integer cb;
	while(geti(pa, LAST) == 0 && ((ca = count(pa)) > 0))
		pa = delitem(pa, LAST);
	while(geti(pb, LAST) == 0 && ((cb = count(pb)) > 0))
		pb = delitem(pb, LAST);
	
	if(ca == 0) {
		ca = 1;
		pa = ["0"];
	}
	if(cb == 0) {
		cb = 1;
		pb = ["0"];
	}
	
	integer i;
	while(i < ca && i < cb) {
		integer ja = (integer)gets(pa, i);
		integer jb = (integer)gets(pb, i);
		if(ja > jb)
			return -(i + 1);
		else if(ja < jb)
			return (i + 1);
		++i;
	}
	
	if(ca > cb)
		return -(cb+1);
	else if(ca < cb)
		return (ca+1);
	
	return 0;
}

#endif // _ARES_VERSION_COMPARE_H_
