
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  REQUEST.H.LSL Header Component
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

#ifndef _ARES_REQUEST_H_
#define _ARES_REQUEST_H_

// lookup functions - implemented in proc
// returns data to a pipe; create a pipe to receive results, or use OUTPUT_SAY as a placeholder for testing

// in all of these lookup functions, _user is relayed passively, and can be replaced with a handle

// http_get(): GETs a web address
#define http_get(_url, _outs, _user) notify_program("proc fetch " + _url, _outs, NULL_KEY, _user)

// http_get but with headers (use llHTTPRequest() format):
#define http_get_extended(_url, _outs, _user, ...) notify_program("proc fetch " + _url + " " + jsarray(__VA_ARGS__), _outs, NULL_KEY, _user)

// http_post(): POSTs the input stream to a web address - use pipe_write() with a generated key to populate the input stream
#define http_post(_url, _outs, _ins, _user) notify_program("proc fetch " + _url, _outs, _ins, _user)

// http_post() but with headers (use llHTTPRequest() format):
#define http_post_extended(_url, _outs, _ins, _user, ...) notify_program("proc fetch " + _url + " " + jsarray(__VA_ARGS__), _outs, _ins, _user)

// request_uuid(): returns agent key
#define request_uuid(_agent, _outs, _user) notify_program("proc uuid " + _agent, _outs, NULL_KEY, _user)
// request_name(): returns modern-style username
#define request_name(_agent, _outs, _user) notify_program("proc name " + _agent, _outs, NULL_KEY, _user)
// request_avatar(): returns vintage-style Firstname Lastname
#define request_avatar(_agent, _outs, _user) notify_program("proc avatar " + _agent, _outs, NULL_KEY, _user)
// request_online(): returns 1 if online, 0 if offline
#define request_online(_agent, _outs, _user) notify_program("proc online " + _agent, _outs, NULL_KEY, _user)
// request_born(): returns birthdate in SLT
#define request_born(_agent, _outs, _user) notify_program("proc born " + _agent, _outs, NULL_KEY, _user)

// request_payinfo(): returns 1 if payment info on file, 0 if not
#define request_payinfo(_agent, _outs, _user) notify_program("proc payinfo " + _agent, _outs, NULL_KEY, _user)

// request_regionpos(): returns coordinates of a region
#define request_regionpos(_region, _outs, _user) notify_program("proc regionpos " + _region, _outs, NULL_KEY, _user)

// request_regionstatus(): returns status of a region
#define request_regionstatus(_region, _outs, _user) notify_program("proc regionstatus " + _region, _outs, NULL_KEY, _user)

// request_regionrating(): returns rating of a region
#define request_regionrating(_region, _outs, _user) notify_program("proc regionrating " + _region, _outs, NULL_KEY, _user)

/*
	_proc http server API (all done with SIGNAL_NOTIFY)
	
	your program must generate the messages:
		_proc listen <callback> (to start listening)
		_proc release <callback> (to end listening)
		_proc reply <condition> (when a query comes in - set ins to Q)
	
	// <condition> is the HTTP status code, ideally 200
	
	(the macros below will take care of these)
	
	you will receive:
		<callback> http://<URL> (when created or re-created)
		<callback> URL_REQUEST_DENIED (when things fail)
		<callback> <any other URL fragment, may be blank or start with / or ?> (when receiving a message, check input pipe, ins=request body, outs=Q)
	
	<callback> will be activated with ins=request body and outs=Q
	
	parse request body with read(), then send your response to Q with pipe_write() (don't use print())
	then call _proc reply <condition> to send the message
	
	servers are automatically recreated on region change, which will cause a new http://<URL> to be provided
	HTTPS is not supported (yet)
*/

#define http_listen(_callback, _user) notify_program("_proc listen " + PROGRAM_NAME + " " + (_callback), NULL_KEY, NULL_KEY, _user)
#define http_release(_callback) notify_program("_proc release " + PROGRAM_NAME + " " + (_callback), NULL_KEY, NULL_KEY, NULL_KEY)
#define http_reply(_Q, _condition, _body) { pipe_write(_Q, _body); notify_program("_proc reply " + (string)(_condition), NULL_KEY, _Q, NULL_KEY); }

#endif // _ARES_REQUEST_H_
