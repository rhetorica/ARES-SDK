
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  API.H.LSL Header Component
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
	FOUNDATIONAL SYSTEM CALLS
	
	IMPORTANT: When required to provide a UUID to the ARES API by these or any other functions, never pass an empty string. Instead use NULL_KEY. Some parts of the OS assume fixed-length message prefixes and will break if fed the wrong thing.
*/

#ifndef _ARES_API_H_
#define _ARES_API_H_

// send a command to the kernel:
#define kernel(_message_number, _message) linked(R_KERNEL, _message_number, E_PROGRAM_NUMBER + _message, "")

// send a message to the system (via the kernel):
#define system(_message_number, _message) linked(R_KERNEL, _message_number, _message, "")

// daemon call (message below 0xf00):
#define call(_daemon_channel, _message_number, _message) tell(DAEMON, _daemon_channel, ares_encode(_message_number) + E_PROGRAM_NUMBER + _message)

// pre-encoded daemon call (message below 0xf00):
#define e_call(_daemon_channel, _e_message_number, _message) tell(DAEMON, _daemon_channel, _e_message_number + E_PROGRAM_NUMBER + _message)

// run a program via command line (as though called by a user):
#define invoke(_command, _output_pipe, _input_pipe, _user) system(SIGNAL_INVOKE, E_UNKNOWN + E_PROGRAM_NUMBER + (string)(_output_pipe) + " " + (string)(_input_pipe) + " " + (string)(_user) + " " + _command)

// request a program be terminated:
#define terminate(_program) system(SIGNAL_TERMINATE, E_UNKNOWN + E_PROGRAM_NUMBER + _program)

// send a notification to a program (used for file i/o and sharing status changes):
#define notify_program(_command, _output_pipe, _input_pipe, _user) system(SIGNAL_NOTIFY, E_UNKNOWN + E_PROGRAM_NUMBER + (string)(_output_pipe) + " " + (string)(_input_pipe) + " " + (string)(_user) + " " + _command)

// send a notification to a daemon (see C_* constants in ARES/a for channels):
#define notify_daemon(_daemon_channel, _command, _output_pipe, _input_pipe, _user) tell(DAEMON, _daemon_channel, E_SIGNAL_NOTIFY + E_PROGRAM_NUMBER + (string)(_output_pipe) + " " + (string)(_input_pipe) + " " + (string)(_user) + " " + _command)

// send a message from one daemon to another (message number is unencoded)
#define daemon_to_daemon(_e_daemon, _message_number, _message) system(_message_number, _e_daemon + E_PROGRAM_NUMBER + _message)

/* Inclusions of ARES API components */

#include <ARES/api/io.h.lsl>
#include <ARES/api/hardware.h.lsl>
#include <ARES/api/status.h.lsl>
#include <ARES/api/effector.h.lsl>
#include <ARES/api/repair.h.lsl>
#include <ARES/api/interface.h.lsl>
#include <ARES/api/kernel.h.lsl>
#include <ARES/api/scheduler.h.lsl>
#include <ARES/api/storage.h.lsl>
#include <ARES/api/tasks.h.lsl>
#include <ARES/api/database.h.lsl>
#include <ARES/api/request.h.lsl>

/*
	The following modules provide function implementations rather than convenient ways to make existing system calls, and are therefore not automatically included:
	
	auth.h.lsl
	file.h.lsl
	interface.consts.h.lsl
	version-compare.h.lsl
*/

#endif // _ARES_API_H_
