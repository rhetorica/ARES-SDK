
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  INTERFACE.H.LSL Header Component
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

#ifndef _ARES_INTERFACE_H_
#define _ARES_INTERFACE_H_

// **** interface daemon ****

// interface_sound(): play a system sound effect to the unit only (must be named in LSD:interface.sound)
#define interface_sound(_name) e_call(C_INTERFACE, E_SIGNAL_CALL, \
						(string)avatar + " " + (string)avatar + " interface sound " + _name)


// fixed_warning(slot, msg): display a fixed warning message on the UI (see values in interface.consts.h.lsl)
#define fixed_warning(_slot, _msg) \
			system(SIGNAL_TRIGGER_EVENT, (string)EVENT_WARNING + " " + (string)(_slot) + " " + (string)(_msg))

// **** variatype daemon ****

/* alert(): create an alert message on the HUD
		_message: the text to show (must fit in 12 variatype cells, approx. 96 chars)
		_icon: 0-4 (icon 0 does not play sound)
		_color: 0 for normal (color d), 1 for bad (color c)
		_buttons: 0 for consent prompt, 1 for menu prompt, 2 for OK/details, 3 for OK only, 4 for ignore/help/run/delete
		then: a list of actions to be invoked, one for each button
	every alert acknowledgement will always clear the message
	provide "!clear" as an action for just closing the prompt
	any _buttons other than 0 will cause the alert to time out after a few seconds
	
	example: alert("hi", 0, 0, 3, ["!clear"]) simply shows "hi" with dismissal option
	
	the constants below can help make your alerts easier to read in code
*/

#define ALERT_ICON_INFO 0
#define ALERT_ICON_PERMISSION 1
#define ALERT_ICON_DATA 2
#define ALERT_ICON_HARDWARE 3
#define ALERT_ICON_ERROR 4

#define ALERT_COLOR_NORMAL 0
#define ALERT_COLOR_BAD 1

#define ALERT_BUTTONS_CONSENT 0
#define ALERT_BUTTONS_MENU 1
#define ALERT_BUTTONS_DETAILS 2
#define ALERT_BUTTONS_DISMISS 3
#define ALERT_BUTTONS_AUTOEXEC 6

#define alert(_message, _icon, _color, _buttons, ...) e_call(C_VARIATYPE, E_SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " variatype alert " + _message + "\n" + (string)(_icon) + "\n" + (string)(_color) + "\n" + (string)(_buttons) + "\n" + jsarray(__VA_ARGS__))

// send a HUD alert message from a daemon:
#define daemon_alert(_message, _icon, _color, _buttons, ...) daemon_to_daemon(E_VARIATYPE, E_SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " variatype alert " + _message + "\n" + (string)(_icon) + "\n" + (string)(_color) + "\n" + (string)(_buttons) + "\n" + jsarray(__VA_ARGS__))

// command_prompt(outs, ins, user, message, command_prefix): prompt a user for parameters to append to command_prefix, then execute it. A space is automatically inserted between command_prefix and the user-supplied parameters.
#define command_prompt(_outs, _ins, _user, _message, _command_prefix) e_call(C_BASEBAND, E_SIGNAL_CALL, (string)_outs + " " + (string)_user + " baseband prompt " + jsobject(["message", _message, "ins", _ins, "command", _command_prefix]))

#endif // _ARES_INTERFACE_H_
