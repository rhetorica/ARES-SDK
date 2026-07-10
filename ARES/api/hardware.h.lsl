
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2026 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  HARDWARE.H.LSL Header Component
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

#ifndef _ARES_HARDWARE_H_
#define _ARES_HARDWARE_H_

// **** hardware daemon ****

#define device_list() e_call(C_HARDWARE, E_SIGNAL_DATA_LIST, "")

#if defined(RING_NUMBER) && RING_NUMBER <= R_DAEMON
	#define call_hardware(_outs, _user, _args) daemon_to_daemon(E_HARDWARE, SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " hardware " + _args)
#else
	#define call_hardware(_outs, _user, _args) e_call(C_HARDWARE, E_SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " hardware " + _args)
#endif

#define device_command(_device_address, _command, _outs, _user) call_hardware(_outs, _user, (_device_address) + " " + (_command))
#define device_probe() call_hardware(NULL_KEY, NULL_KEY, "probe")

#endif
