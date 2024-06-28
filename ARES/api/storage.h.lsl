
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  STORAGE.H.LSL Header Component
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

#ifndef _ARES_STORAGE_H_
#define _ARES_STORAGE_H_

/*
	NEW UNIFORM FILE ACCESS SYSTEM - ARES 0.4.4
	
	replaces ARES/api/fs.h.lsl
*/

#define FILE_PAGE_LENGTH 1024
#define FILE_LINE_WIDTH 1024

// open a pipe and performs a stat (requests file info):
#define file_open(_pipe, _filename) file_read(_pipe, _filename, NOWHERE);

/*
	file stat in ARES 0.4.4

	When a file is opened, _storage will send the following fields to your application via a notify "<program> file" pipe:
   
	  <size> <unit> <type> <description>   

	The fields are space-separated and have the following definitions:
		<size> is the length of the file, measured in <unit>.
		<unit> is b for bytes, p for pages, or l for lines.
		<type> is d for directory, o for unreadable objects, and f for readable text files.
		<description> is a freeform string (e.g. llGetInventoryDesc()) and may not be present.
	
	Attempting to read an object file will cause an error. (These were added to represent SL inventory items with no interpretable contents.) Attempting to read a directory will give a linebreak-separated list of names therein. The special file "<source>:*" will list all files in <source>, e.g. "local:*".
	
	The "<source>:" prefix can also be used to disambiguate files with identical names, but finding them in the first place may be nontrivial; the behavior of fs:root when multiple files with the same name are present in different sources is currently undefined and will generally cause problems.
*/

/*
    file read in ARES 0.4.4
	
	Once the file is opened and you have received its stat values (above), you can then ask _storage to start sending data. To successfully iterate through a file, you need to look at the unit and then request appropriate sections with file_read().
	
	The offset parameter of file_read() may be a single number or <start> <length> (with a " " in the middle). If no <length> is missing, then only 1 unit will be returned. If your application can handle it, you should simply request the entire file using the <size> given by the file_open() macro.
	
	If the <unit> is b, then you will only get one byte at a time if you fail to specify <length>, which is not very useful. Instead use a larger window, like 1024 or 2048, and iterate over the file to the best of your program's memory-handling abilities.
	
	If you request data from an "l" file, a linebreak will always be added on the end so that the text can be concatenated properly without worrying about the underlying format.

*/
#define file_read(_pipe, _filename, _offset) e_call(C_IO, E_SIGNAL_DATA_REQUEST, (string)(_pipe) + " " + PROGRAM_NAME + " " + (_filename) + " " + (string)(_offset))

// just closes the pipe; the storage protocol is stateless:
#define file_close(_pipe) e_call(C_IO, E_SIGNAL_DELETE_RULE, "[\"" + (string)(_pipe) + "\"]")

// write text directly into a filename (provided the target filesystem supports and allows it). 
// fill _pipe using pipe_write(), then call this to send the data.
// NOTE: the file will be OVERWRITTEN. Use file_append() if you do not want this.
#define file_write(_filename, _pipe) e_call(C_STORAGE, E_SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " storage write " + (_filename) + " " + (string)(_pipe))
#define file_append(_filename, _pipe) e_call(C_STORAGE, E_SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " storage append " + (_filename) + " " + (string)(_pipe))

// delete a file, provided the filesystem supports and allows it.
#define file_delete(_filename) e_call(C_STORAGE, E_SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " storage delete " + (_filename))

// OTHER FILESYSTEM ACTIVITIES

// get all filenames in a view:
#define view_files(_rule) js2list(llLinksetDataRead("fs:"+_rule))
// get all filenames in a source:
#define source_files(_rule) split(llLinksetDataRead("fs:"+_rule), "\n")

// get all filenames (careful; this can be huge):
#define list_all_files() jskeys(llLinksetDataRead("fs:root"))

// refresh a source:
#define storage_refresh(_source, _callback, _user) e_call(C_STORAGE, E_SIGNAL_CALL, (string)(_callback) + " " + (string)(_user) + " storage refresh " + (_source))

#endif // _ARES_STORAGE_H_
