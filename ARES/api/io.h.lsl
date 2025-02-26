
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  IO.H.LSL Header Component
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

#ifndef _ARES_IO_H_
#define _ARES_IO_H_

// **** IO daemon ****

// create a pipeline; parameter should be a list of strings, each of which describes a pipe to create
/*
  // individual pipes use the format:
	[p:<key>] [n:<key>] <type-spec>

  - p:<key> is optional; it specifies a UUID to use for the pipe (otherwise this is generated randomly)
  - n:<key> is optional; it overrides the pipe this will send to (required if you want complete control over the UUIDs of a pipeline)
  - the <type-spec> is one of:
       notify <program>: triggers the program using SIGNAL_NOTIFY (volatile)
	   invoke <program>: triggers the program using SIGNAL_INVOKE (volatile)
	   signal <program>: triggers the program using SIGNAL_NOTIFY (non-volatile)
	   permanent <program>: triggers the program using SIGNAL_INVOKE (non-volatile)
	   to <channel> <UUID>: sends messages to <UUID> on <channel> (non-volatile) - will not send messages to subsequent pipes
	   from <channel> <UUID> <program>: listens for messages from <UUID> on <channel> and invokes <program> (non-volatile) - will not pass on messages from prior pipes; specify <UUID> as NULL_KEY to listen to messages from any object; be aware that the user key provided by 'from' will be the object UUID rather than the owning avatar
	   transport: simply passes messages to the output pipe (non-volatile)
	   print: simply passes messages to the output pipe (volatile)
	   <program>: if no type identifier is included, the pipe is assumed to be a volatile SIGNAL_INVOKE pipe
  
  file_open() automatically creates a special pipe which is functionally identical to a volatile SIGNAL_NOTIFY pipe, but automatically removes the linebreaks at the start of the buffer caused by print()
  
  volatile pipes are purged on rez by io
  invokes will purge their pipes when they finish, unless the pipes are non-volatile or the input stream's UUID is currently assigned to a task
  
  non-volatile pipes are never purged or destroyed.
   
  after creation, the program will receive SIGNAL_NOTIFY with the message "* pipe <definition>" for each pipe generated, with ins == the pipe key and outs == the next key.
*/

#define pipe_open(...) e_call(C_IO, E_SIGNAL_CREATE_RULE, jsarray((__VA_ARGS__)))

// delete a series of pipes (provide as a list of keys):
#define pipe_close(...) e_call(C_IO, E_SIGNAL_DELETE_RULE, jsarray((__VA_ARGS__)))

// as pipe_close, but only remove volatile invoke pipes:
#define pipe_close_volatile(...) e_call(C_IO, E_SIGNAL_DELETE_RULE, "V" + jsarray((__VA_ARGS__)))

// assign a new next pipe to an existing pipe:
#define pipe_extend(__pipe, __next) e_call(C_IO, E_SIGNAL_CREATE_RULE, jsarray(("p:" + (string)(__pipe) + " n:" + (string)(__next))))

#undef SAFE_EOF
#define SAFE_EOF ""

// read a message from a pipe and store it in the destination variable:
#define pipe_read(_pipe_key, _dest_var) { _dest_var = read(_pipe_key); }

string read(key pipe) {
	string spipe = "p:" + (string)pipe;
	string buffer = llLinksetDataRead(spipe);
	integer eor = strpos(buffer, SAFE_EOF);
	
	if(~eor) {
		if(eor == strlen(buffer) - 1)
			llLinksetDataDelete(spipe);
		else
			llLinksetDataWrite(spipe, delstring(buffer, 0, eor));
		buffer = delstring(buffer, eor, LAST);
	} else {
		llLinksetDataDelete(spipe);
	}
	
	return buffer;
}

// send a list of pipe chains to _outs, starting from the specified head pipe(s):
#define pipe_list(_outs, _user, ...) e_call(C_IO, E_SIGNAL_QUERY_RULES, (string)(_outs) + " " + (string)(_user) + " " + concat((list)(__VA_ARGS__), " "))

// print(outs, user, message): print message to pipe outs on behalf of user

#if defined(RING_NUMBER) && RING_NUMBER <= R_DAEMON
	#define print(_pipe_key, _user, _message) { llLinksetDataWrite("p:" + (string)(_pipe_key), llLinksetDataRead("p:" + (string)(_pipe_key)) + _message + SAFE_EOF); linked(R_KERNEL, SIGNAL_CALL, E_IO + E_PROGRAM_NUMBER + (string)(_pipe_key) + " " + (string)(_user) + " io", ""); }
#else
	#define print(_pipe_key, _user, _message) { llLinksetDataWrite("p:" + (string)(_pipe_key), llLinksetDataRead("p:" + (string)(_pipe_key)) + _message + SAFE_EOF); tell(DAEMON, C_IO, E_SIGNAL_CALL + E_PROGRAM_NUMBER + (string)(_pipe_key) + " " + (string)(_user)); }
#endif

// send messages directly through io on an arbitrary channel (needed for RLV relay, AX, etc.):
#define io_tell(_target, _channel, _message) tell(DAEMON, C_IO, E_SIGNAL_TELL + E_PROGRAM_NUMBER + (string)(_target) + " " + (string)(_channel) + " " + _message)
#define io_broadcast(_channel, _message) io_tell(NULL_KEY, _channel, _message)

// silently add a message to a pipe so it can be found later:
#define pipe_write(_pipe_key, _message) llLinksetDataWrite("p:" + (string)(_pipe_key), llLinksetDataRead("p:" + (string)(_pipe_key)) + _message + SAFE_EOF)

// tell _io to process a pipe without adding anything to it:
#if defined(RING_NUMBER) && RING_NUMBER <= R_DAEMON
	#define pipe_push(_pipe_key, _user) { linked(R_KERNEL, SIGNAL_CALL, E_IO + E_PROGRAM_NUMBER + (string)(_pipe_key) + " " + (string)(_user) + " io", ""); }
#else
	#define pipe_push(_pipe_key, _user) { tell(DAEMON, C_IO, E_SIGNAL_CALL + E_PROGRAM_NUMBER + (string)(_pipe_key) + " " + (string)(_user)); }
#endif

#endif // _ARES_IO_H_
