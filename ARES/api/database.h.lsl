
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  DATABASE.H.LSL Header Component
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

/*
	LSD DATABASE I/O

	Read, write, and delete database entries.
	
	There are two sets of macros for interacting with the Linkset datastore. The first set has names ending in 'dbl', and the second set has names ending in 'db'.
	
	The 'dbl' macros assume the key name is already split into a list (the same as LSL's JSON functions) and are therefore more efficient.
	
	The 'db' macros will do this for you; you should only need these for handling user input.
	
	Occasionally when working with many entries in one section, you may still find it memory-efficient to use the llLinksetData* functions with getjs(). There are no macros for this because you should only be doing it once or twice per program.
*/

#ifndef _ARES_DATABASE_H_
#define _ARES_DATABASE_H_

// use as setdbl(section, ["list", "of", "subkey", "names"], value)
#define setdbl(_section, ...) llLinksetDataWrite(_section, setjs(llLinksetDataRead(_section), __VA_ARGS__))
#define getdbl(_section, ...) getjs(llLinksetDataRead(_section), __VA_ARGS__)
#define deletedbl(_section, ...) llLinksetDataWrite(_section, setjs(llLinksetDataRead(_section), __VA_ARGS__, JSON_DELETE))

// use as setdbl(section, "string.of.subkey.names", value)
#define setdb(_section, _entry, _value) llLinksetDataWrite(_section, setjs(llLinksetDataRead(_section), splitnulls(_entry, "."), _value))
#define getdb(_section, _entry) getjs(llLinksetDataRead(_section), splitnulls(_entry, "."))
#define deletedb(_section, _entry) llLinksetDataWrite(_section, setjs(llLinksetDataRead(_section), splitnulls(_entry, "."), JSON_DELETE))

#endif // _ARES_DATABASE_H_
