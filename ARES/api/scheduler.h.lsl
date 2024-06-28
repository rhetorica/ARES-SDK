
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  SCHEDULER.H.LSL Header Component
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

#ifndef _ARES_SCHEDULER_H_
#define _ARES_SCHEDULER_H_

/*
	EVENT HOOKS
	
	This asks the scheduler to notify your program when something important happens. The list of supported events can be found in the <ARES/a> header.
*/

// hooking and unhooking events (provide a list of EVENT_* constants):
#if defined(RING_NUMBER) && RING_NUMBER <= R_DAEMON
	#define query_hooks() kernel(SIGNAL_QUERY_HOOKS, "")
	#define hook_events(...) kernel(SIGNAL_HOOK_EVENT, PROGRAM_NAME + "," + concat(__VA_ARGS__, ","))
	#define unhook_events(...) kernel(SIGNAL_UNHOOK_EVENT, PROGRAM_NAME + "," + concat(__VA_ARGS__, ","))
#else
	#define query_hooks() tell(DAEMON, C_SCHEDULER, E_SIGNAL_QUERY_HOOKS + PROGRAM_NAME)
	#define hook_events(...) tell(DAEMON, C_SCHEDULER, E_SIGNAL_HOOK_EVENT + PROGRAM_NAME + "," + concat(__VA_ARGS__, ","))
	#define unhook_events(...) tell(DAEMON, C_SCHEDULER, E_SIGNAL_UNHOOK_EVENT + PROGRAM_NAME + "," + concat(__VA_ARGS__, ","))
#endif

// create a timer (interval must be an integer)
// delete by setting interval to 0
// tag is an arbitrary string used to disambiguate multiple timers for the same program
// note that timers must be recreated if the kernel resets, since they are PID-based
// (non-timer events survive)
#define set_timer(_tag, _interval) tell(DAEMON, C_SCHEDULER, E_SIGNAL_TIMER + E_PROGRAM_NUMBER + (string)(_interval) + " " + _tag)

#endif // _ARES_SCHEDULER_H_
