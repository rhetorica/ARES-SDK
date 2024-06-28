/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *               Copyright (c) 2023 Nanite Systems Corporation              
 *  
 * =========================================================================
 *
 *  FILE.H.LSL Header Component
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

#ifndef _ARES_FILE_H_
#define _ARES_FILE_H_

#include <utils.lsl>

#define FILE_R 0
#define FILE_INS 1
#define FILE_OUTS 2
#define FILE_USER 3
#define FILE_NAME 4
#define FILE_OFFSET 5
#define FILE_LENGTH 6
#define FILE_UNIT 7

/*
	NEW UNIFORM FILE ACCESS SYSTEM - ARES 0.4.4
	
	replaces ARES/api/file.h.lsl
*/

/*
	To use this script, call fopen() with the 'outs', 'ins', and 'user' from main()

	When file contents are available, the program will receive:

	SIGNAL_NOTIFY
		message: PROGRAM_NAME + " file"
		ins: matching the file_handle returned by fopen()

	You can then call fread(file_handle) to get contents.
	
	fread() has the following special return values:
		JSON_FALSE: file does not exist or file is empty
		JSON_TRUE: file was opened successfully and data will arrive soon
	
	If fread() returns any other value, it is file data.
	
	fread() reads files in buffer chunks of around 1024 bytes, or one line for notecards, and always advances to the next chunk afterward.
	
	fread() will close the file automatically when it is done reading, at which point getjs(tasks_queue, [file_handle]) will return JSON_INVALID.
	
	By default, this API will automatically try to resolve tasks for you when the file is closed. This is good for simple file readers but wrong if you intend to do more processing afterward. To suppress this behavior, set '_resolved = 0' before calling fopen(), and pass NULL_KEY for ins.
*/

#ifndef FILE_STEP_SIZE
	// define this as a small integer for speed-ups (don't go too far, though)
	#define FILE_STEP_SIZE 1
#endif

// fopen(output_stream, input_stream, user_key, file_name): returns file_handle
key fopen(key outs, key ins, key user, string filename) {
	key q = llGenerateKey();
	// send request to io daemon to create pipe and fetch file length:
	file_open(q, filename);
	
	// track file information and prevent job from sleeping during load process
	string metadata = list2js(JSON_ARRAY, [
		_resolved, // callback number for program that summoned us
		ins, // original input stream (often used as a callback handle)
		outs, // output stream
		user, // user that initiated the request
		filename, // filename being worked on
		NOWHERE, // file offset (haven't started reading yet)
		NOWHERE, // file length (loaded first)
		"" // file unit (loaded with file length)
	]);
	task_begin(q, metadata);
	// metadata is stored in the global JSON variable tasks_queue, and can be accessed later
	
	_resolved = 0;
	return q;
}

// fread(file_handle): returns JSON_TRUE if file opened successfully, JSON_FALSE if file empty/missing, otherwise file text
// note that it may return up to 1025 bytes for a perfectly full notecard line + linebreak, but will otherwise always return 1024 bytes or fewer
string fread(key q) {
	// split apart file metadata into a list (smaller code)
	list file = js2list(getjs(tasks_queue, [q]));
	integer file_length = geti(file, FILE_LENGTH);
	string file_unit = gets(file, FILE_UNIT);
	string fn = gets(file, FILE_NAME);
	
	// copy contents of LSD pipe into local variable:
	string buffer;
	pipe_read(q, buffer);
	
	integer offset = geti(file, FILE_OFFSET);
	_resolved = 0;
	
	if(!~file_length) {
		// on the first successful call we load the file length and unit
		list stat_parts = split(buffer, " ");
		file_length = (integer)gets(stat_parts, 0);
		file_unit = gets(stat_parts, 1);
		tasks_queue = setjs(setjs(tasks_queue,
			[q, FILE_LENGTH], (string)file_length),
			[q, FILE_UNIT], (string)file_unit);
		
		// for notecards, file length is measured as the number of lines,
		// NOT the actual character count
		
		if(file_length > 0) {
			// a length greater than 0 indicates the file exists
			// start reading file
			offset = 0;
			
			integer read_length = FILE_STEP_SIZE;
			if(file_unit == "b")
				read_length *= FILE_PAGE_LENGTH;
			
			if(read_length > file_length)
				read_length = file_length;
			
			file_read(q, fn, (string)offset + " " + (string)read_length);
			
			tasks_queue = setjs(tasks_queue, [q, FILE_OFFSET], (string)offset);
			buffer = JSON_TRUE;
		} else {
			// no file was found, or file was empty
			file_close(q);
			
			// job can now end:
			// resolve_io(geti(file, FILE_R), getk(file, FILE_OUTS), getk(file, FILE_INS));
			resolve_i(geti(file, FILE_R), getk(file, FILE_INS));
			task_end(q);
			buffer = JSON_FALSE;
		}
	} else {
		// got length earlier, so this must be file data
	
		// move forward to next page:
		if(file_unit == "b")
			offset += (FILE_PAGE_LENGTH * FILE_STEP_SIZE);
		else
			offset += (FILE_STEP_SIZE);
		
		// is there more file?
		if(offset < file_length) {
			// record new offset:
			tasks_queue = setjs(tasks_queue, [q, FILE_OFFSET], (string)offset);
			// get next section:
			#ifdef DEBUG
			echo("file.h.lsl: loading offset " + (string)offset + "/" + (string)file_length);
			#endif
			
			integer read_length = FILE_STEP_SIZE;
			if(file_unit == "b")
				read_length *= FILE_PAGE_LENGTH;
			
			if(read_length + offset > file_length)
				read_length = file_length - offset;
			
			file_read(q, fn, (string)offset + " " + (string)read_length);
		} else {
			// reached end of file
			file_close(q);
			
			// job can now end:
			// resolve_io(geti(file, FILE_R), getk(file, FILE_OUTS), getk(file, FILE_INS));
			resolve_i(geti(file, FILE_R), getk(file, FILE_INS));
			// delete file handle:
			task_end(q);
		}
	}
	
	// send data to the program
	return buffer;
}

// preview what fread() will return without actually initiating the next file request
string fpeek(key q) {
	// split apart file metadata into a list (smaller code)
	list file = js2list(getjs(tasks_queue, [q]));
	integer file_length = geti(file, FILE_LENGTH);
	
	// copy contents of LSD pipe into local variable:
	string buffer = llLinksetDataRead("p:" + (string)q);
	
	if(!~file_length) {
		// on the first successful call we load the file length
		file_length = (integer)buffer;
		// tasks_queue = setjs(tasks_queue, [q, FILE_LENGTH], (string)file_length);
		
		// for notecards, file length is measured as 256 * (number of lines),
		// NOT the actual character count
		
		if(file_length > 0) {
			// a length greater than 0 indicates the file exists
			buffer = JSON_TRUE;
		} else {
			// no file was found, or file was empty
			buffer = JSON_FALSE;
		}
	}
	
	// send data to the program
	return buffer;
}

// abort file reading (only needed when using fpeek()):
fclose(key q) {
	// split apart file metadata into a list (smaller code)
	list file = js2list(getjs(tasks_queue, [q]));
	
	file_close(q);
	
	// job can now end:
	// resolve_io(geti(file, FILE_R), getk(file, FILE_OUTS), getk(file, FILE_INS));
	resolve_i(geti(file, FILE_R), getk(file, FILE_INS));
	// delete file handle:
	task_end(q);
}

#endif // _ARES_FILE_H_
