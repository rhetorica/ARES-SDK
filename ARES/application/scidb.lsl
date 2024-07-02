/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Scientific Database Lookup Utility
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
#define CLIENT_VERSION "0.2.1"
#define CLIENT_VERSION_TAGS "alpha"

string DEFAULT_DOMAIN = "eutils.ncbi.nlm.nih.gov";
string DEFAULT_DB = "pubmed";
string DEFAULT_QUERY_KEY = "1";

#define SEARCH_STRING(DB, Q) "/entrez/eutils/esearch.fcgi?usehistory=y&db=" + llEscapeURL(DB) + "&term=" + llEscapeURL(Q)
#define POST_STRING(DB, Q) "/entrez/eutils/epost.fcgi?usehistory=y&db=" + llEscapeURL(DB) + "&id=" + llEscapeURL(Q)
#define SUMMARY_STRING(DB, Q, ENV) "/entrez/eutils/esummary.fcgi?usehistory=y&db=" + llEscapeURL(DB) + "&query_key=" + llEscapeURL(Q) + "&WebEnv=" + llEscapeURL(ENV)
#define ABSTRACT_STRING(DB, Q, ENV) "/entrez/eutils/efetch.fcgi?usehistory=y&db=" + llEscapeURL(DB) + "&query_key=" + llEscapeURL(Q) + "&WebEnv=" + llEscapeURL(ENV) + "&rettype=abstract&retmode=text"
#define FASTA_STRING(DB, Q, ENV) "/entrez/eutils/efetch.fcgi?usehistory=y&db=" + llEscapeURL(DB) + "&query_key=" + llEscapeURL(Q) + "&WebEnv=" + llEscapeURL(ENV) + "&rettype=fasta&retmode=text"

key scidb_receive_pipe;
string waiting_queries = "{}";
string queries_in_progress = "{}";

#define MODE_SEARCH 0
#define MODE_SUMMARY 1
#define MODE_ABSTRACT 2
#define MODE_FASTA 3

send_query(string query, key handle) {
	string domain = getjs(query, [4]);
	string database = getjs(query, [5]);
	string question = getjs(query, [6]);
	integer mode = (integer)getjs(query, [7]);
	string query_key = getjs(query, [8]);
	
	queries_in_progress = setjs(queries_in_progress, [(string)handle], query);
	string url;
	if(mode == MODE_SEARCH)
		url = domain + SEARCH_STRING(database, question);
	else if(mode == MODE_SEARCH)
		url = domain + POST_STRING(database, question);
	else if(mode == MODE_SUMMARY)
		url = domain + SUMMARY_STRING(database, query_key, question);
	else if(mode == MODE_ABSTRACT)
		url = domain + ABSTRACT_STRING(database, query_key, question);
	else if(mode == MODE_FASTA)
		url = domain + FASTA_STRING(database, query_key, question);
	
	http_get(url, scidb_receive_pipe, handle);
}

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		if(argc == 1) {
			msg = "Syntax: " + PROGRAM_NAME + " [-d <database> -m <domain> -q <querykey> -s|-f|-a-p] <query>\n\nLooks up <query> on the specified [https://www.ncbi.nlm.nih.gov/ NCBI Entrez] database at <domain> (default: " + DEFAULT_DB + " at " + DEFAULT_DOMAIN + "). -s will retrieve summaries from a matching WebEnv query. -q will set the query key (default: 1) -p will post queries to sequence databases. -a will fetch abstracts. -f will fetch FASTA sequences.";
		} else {
			string domain = DEFAULT_DOMAIN;
			string database = DEFAULT_DB;
			integer mode = MODE_SEARCH;
			string query_key = DEFAULT_QUERY_KEY;
			
			string a1;
			integer a1i;
			while(~(a1i = llListFindList(["-m", "-d", "-s", "-f", "-a", "-q"], [a1 = gets(argv, 1)]))) {
				if(a1i == 0) { // -m
					domain = gets(argv, 2);
					argv = delrange(argv, 1, 2);
				} else if(a1i == 1) { // -d
					database = gets(argv, 2);
					argv = delrange(argv, 1, 2);
				} else if(a1i == 5) { // -q
					query_key = gets(argv, 2);
					argv = delrange(argv, 1, 2);
				} else if(a1i == 2) { // -s
					mode = MODE_SUMMARY;
					argv = delrange(argv, 1, 1);
				} else if(a1i == 3) { // -f
					mode = MODE_FASTA;
					argv = delrange(argv, 1, 1);
				} else if(a1i == 4) { // -a
					mode = MODE_ABSTRACT;
					argv = delrange(argv, 1, 1);
				} 
			}
			string question = concat(delitem(argv, 0), " ");
			
			if(!~strpos(domain, "://"))
				domain = "https://" + domain;
			
			key handle = llGenerateKey();
			string query = jsarray([outs, ins, user, _resolved, domain, database, question, mode, query_key]);
			_resolved = 0;
			
			llSetMemoryLimit(0x10000);
			if(scidb_receive_pipe) {
				queries_in_progress = setjs(queries_in_progress, [handle], query);
				send_query(query, handle);
			} else {
				scidb_receive_pipe = llGenerateKey();
				waiting_queries = setjs(waiting_queries, [handle], query);
				pipe_open(["p:"+(string)scidb_receive_pipe + " notify " + PROGRAM_NAME + " response"]);
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
				
				send_query(query, handle);
				++qi;
			}
		} else if(cmd == "response") {
			string query = getjs(queries_in_progress, [(string)user]);
			if(query != JSON_INVALID) {
				key o_outs = getjs(query, [0]);
				key o_ins = getjs(query, [1]);
				key o_user = getjs(query, [2]);
				integer o_rc = (integer)getjs(query, [3]);
				
				string buffer;
				pipe_read(ins, buffer);
				/* string fieldset = getjs(buffer, ["query", "pages", 0]);
				string field;
				if(fieldset != JSON_INVALID) {
					if(getjs(fieldset, ["missing"]) == JSON_TRUE) {
						field = getjs(fieldset, ["title"]) + " does not exist (" + getjs(query, [0]) + "/)";
					} else {
						field = getjs(fieldset, ["extract"]);
					}
				} else {
					field = buffer;
				} */
				
				print(o_outs, o_user, buffer);
				// resolve_io(o_rc, o_outs, o_ins);
				queries_in_progress = setjs(queries_in_progress, [(string)user], JSON_DELETE);
				resolve_i(o_rc, o_ins);
			}
			
			if(queries_in_progress == "{}") {
				pipe_close(scidb_receive_pipe);
				scidb_receive_pipe = "";
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
