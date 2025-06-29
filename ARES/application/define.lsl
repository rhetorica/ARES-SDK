/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  define Dictionary Lookup
 *
 *  This program is covered under the terms of the ARES Software Copyright
 *  License, Section 2 (ASCL-ii). Although it appears in ARES as part of
 *  commercial software, it may be used as the basis of derivative,
 *  non-profit works that retain a compatible license. Derivative works of
 *  ASCL-ii software must retain proper attribution in documentation and
 *  source files as described in the terms of the ASCL. Furthermore, they
 *  must be distributed free of charge and provided with complete, legible
 *  source code included in the package.
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

#include <ARES/a>
#define CLIENT_VERSION "1.1.2"
#define CLIENT_VERSION_TAGS "release"

string DEFAULT_DOMAIN = "en.wikipedia.org";

#define QUERY_STRING "/w/api.php?action=query&format=json&prop=extracts&redirects=1&utf8=1&formatversion=2&exchars=900&explaintext=1&exsectionformat=plain&titles="

key define_receive_pipe;
string waiting_queries = "{}";
string queries_in_progress = "{}";

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		if(argc == 1) {
			msg = "Syntax: " + PROGRAM_NAME + " [-w <domain>] <page>\n\nLooks up <page> on the [https://www.mediawiki.org MediaWiki] at <domain> (default: " + DEFAULT_DOMAIN + ").\n\nThe target wiki must have the [https://www.mediawiki.org/wiki/Extension:TextExtracts TextExtracts API extension] installed.";
		} else {
			string domain;
			if(gets(argv, 1) == "-w") {
				domain = gets(argv, 2);
				argv = delrange(argv, 1, 2);
			} else {
				domain = DEFAULT_DOMAIN;
			}
			string question = concat(delitem(argv, 0), " ");
			
			if(!~strpos(domain, "://"))
				domain = "https://" + domain;
			
			key handle = llGenerateKey();
			string query = jsarray([domain, question, outs, ins, user, _resolved]);
			_resolved = 0;
			
			llSetMemoryLimit(0x10000);
			if(define_receive_pipe) {
				queries_in_progress = setjs(queries_in_progress, [handle], query);
				http_get(domain + QUERY_STRING + llEscapeURL(question), define_receive_pipe, handle);
			} else {
				define_receive_pipe = llGenerateKey();
				waiting_queries = setjs(waiting_queries, [handle], query);
				pipe_open(["p:"+(string)define_receive_pipe + " notify " + PROGRAM_NAME + " response"]);
			}
		}
		
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_NOTIFY) {
		list argv = split(m, " ");
		string cmd = gets(argv, 1);
		if(cmd == "pipe") {
			list queries = jskeys(waiting_queries);
			integer qi = 0;
			integer qmax = count(queries);
			while(qi < qmax) {
				key handle = gets(queries, qi);
				string query = getjs(waiting_queries, [(string)handle]);
				waiting_queries = setjs(waiting_queries, [(string)handle], JSON_DELETE);
				
				string domain = getjs(query, [0]);
				string question = getjs(query, [1]);
				queries_in_progress = setjs(queries_in_progress, [(string)handle], query);
				
				http_get(domain + QUERY_STRING + llEscapeURL(question), define_receive_pipe, handle);
				++qi;
			}
		} else if(cmd == "response") {
			string query = getjs(queries_in_progress, [(string)user]);
			if(query != JSON_INVALID) {
				key o_outs = getjs(query, [2]);
				key o_ins = getjs(query, [3]);
				key o_user = getjs(query, [4]);
				integer o_rc = (integer)getjs(query, [5]);
				
				string buffer;
				pipe_read(ins, buffer);
				string fieldset = getjs(buffer, ["query", "pages", 0]);
				string field;
				if(fieldset != JSON_INVALID) {
					if(getjs(fieldset, ["missing"]) == JSON_TRUE) {
						field = getjs(fieldset, ["title"]) + " does not exist (" + getjs(query, [0]) + "/)";
					} else {
						field = getjs(fieldset, ["extract"]);
					}
				} else {
					field = buffer;
				}
				
				print(o_outs, o_user, field);
				// resolve_io(o_rc, o_outs, o_ins);
				queries_in_progress = setjs(queries_in_progress, [(string)user], JSON_DELETE);
				resolve_i(o_rc, o_ins);
			}
			
			if(queries_in_progress == "{}") {
				pipe_close(define_receive_pipe);
				define_receive_pipe = "";
				llSetMemoryLimit(0x2000);
			}
		}
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		llSetMemoryLimit(0x2000);
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
