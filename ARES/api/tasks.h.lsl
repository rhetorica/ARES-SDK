
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  TASKS.H.LSL Header Component
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

#ifndef _ARES_TASKS_H_
#define _ARES_TASKS_H_

/*
	MODES AND TASK MANAGEMENT
	
	Every program has a bitfield called '_mode' (note the underscore) which defines when the OS will try to put it to sleep. The most common mode flag is MODE_THREADING, which is set automatically while the program has an active task. This should be used whenever the program is waiting for a response from another module, to avoid the 2 second delay of starting back up. Threading jobs will be reset on rez (including sim change, login, attach).
	
	You can begin and end tasks whenever you want.
  
	MODE_NON_VOLATILE is set on programs with '#define NON_VOLATILE' at the top. These programs never go to sleep, and the kernel will not even double-check to make sure they are still flagged as awake when sending them messages. The NON_VOLATILE flag also means the program never gets reset during a rezzing event.
	
	MODE_ACCEPT_DONE means the program will be informed whenever an invoke() or notify() has completed.
*/

string tasks_queue = "{}";

// create a task with the specified tags
// in most cases, you should use ins (the input stream) for _id, as this will protect both the input and output stream from being recycled if they are volatile

#define task_begin(_id, _message) { tasks_queue = setjs(tasks_queue, [_id], _message); system(SIGNAL_MODE, PROGRAM_NAME + "," + (string)(_mode = _mode | MODE_THREADING)); }
#define task_end(_id) (tasks_queue = setjs(tasks_queue, [_id], JSON_DELETE))
#define task_count() count(jskeys(tasks_queue))

// [DEPRECATED/NICHE] politely shut down program (kernel removes MODE_THREADING when this happens, so we don't need to tell it):
// (you may still need this when e.g. ending a real timer-based task)
#define exit() { if(_resolved) system(SIGNAL_DONE, ares_encode(_resolved) + NULL_KEY + " " + PROGRAM_NAME); system(SIGNAL_TERMINATED, PROGRAM_NAME); _mode = _mode & ~MODE_THREADING; llSetScriptState(PROGRAM_NAME, FALSE); llSleep(0.022); }

// [DEPRECATED/NICHE] send a callback key with exit:
#define exitc(_ins) { if(_resolved) system(SIGNAL_DONE, ares_encode(_resolved) + (string)(_ins) + " " + PROGRAM_NAME); system(SIGNAL_TERMINATED, PROGRAM_NAME); _mode = _mode & ~MODE_THREADING; llSetScriptState(PROGRAM_NAME, FALSE); llSleep(0.022); }

// [DEPRECATED] send a receipt for a completed task, without shutting down:
#define resolve(_R) if(_R) system(SIGNAL_DONE, ares_encode(_R) + NULL_KEY + " " + PROGRAM_NAME)

// send a receipt for a completed task (with callback), without shutting down - suitable for modern NV jobs:
#define resolvec(_R, _ins) if(_R) system(SIGNAL_DONE, ares_encode(_R) + (string)(_ins) + " " + PROGRAM_NAME)

// [QUESTIONABLE] send a receipt for a completed task, including callback, and close streams (if they are volatile invoke pipes):
#define resolve_io(_R, _outs, _ins) { pipe_close_volatile([_ins, _outs]); if(_R) system(SIGNAL_DONE, ares_encode(_R) + (string)(_ins) + " " + PROGRAM_NAME); }

// [RECOMMENDED] send a receipt for a completed task, including callback, and close only the input stream (if it is a volatile invoke pipe):
#define resolve_i(_R, _ins) { if(_R) system(SIGNAL_DONE, ares_encode(_R) + (string)(_ins) + " " + PROGRAM_NAME); pipe_close_volatile(_ins); }

// set the program's MODE_* flags and inform the kernel:
#define set_mode(_M) system(SIGNAL_MODE, PROGRAM_NAME + "," + (string)(_mode = _M))

// delay_relock(): informs the policy manager to push back auto-lock, if auto-lock is enabled
#define delay_relock() if((integer)getdbl("policy", ["autolock", "enabled"]) && !(integer)getdbl("policy", ["lock"])) notify_program("policy delay", avatar, NULL_KEY, avatar)

#endif // _ARES_TASKS_H_
