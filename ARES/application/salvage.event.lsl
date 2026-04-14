
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2025–2026 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Salvage Utility - Event Handler
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
 
	#define PROC_NAME "_proc"
 
	timer() {
		if(llGetInventoryType(PROC_NAME) == INVENTORY_SCRIPT
		&& llGetScriptState(PROC_NAME) == 0
		&& llGetLinkNumber() == R_PROGRAM) {
			llWhisper(DEBUG_CHANNEL, "[salvage] A crash in " + PROC_NAME + " has been detected. It will now be reset.");
			llSetScriptState(PROC_NAME, FALSE);
			llSleep(0.5);
			llSetScriptState(PROC_NAME, TRUE);
			llResetOtherScript(PROC_NAME);
		}
	}
