
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  SEXUALITY.H.LSL Header Component
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

#ifndef _ARES_SEXUALITY_H_
#define SEXUALITY_VERSION "0.9.5"
#define SEXUALITY_VERSION_TAGS "preview 4"

#define C_LUST -9999969
#define C_LUST_FX -1010101
#define LUST_INTERNAL_CHANNEL 9996900

#if defined(RING_NUMBER) && RING_NUMBER <= R_DAEMON
	#define call_sexuality(_outs, _user, _args) daemon_to_daemon(E_SEXUALITY, SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " sexuality " + _args)
#else
	#define call_sexuality(_outs, _user, _args) e_call(C_SEXUALITY, E_SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " sexuality " + _args)
#endif

#define update_cryolubricant() call_sexuality(avatar, avatar, "cryolubricant")

list SEXUALITY_MODES = ["disabled", "narrative", "interactive", "masochism"];
#endif // #ifndef _ARES_SEXUALITY_H_
