/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  News RSS Aggregation Client
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
#define CLIENT_VERSION "0.2.3"
#define CLIENT_VERSION_TAGS "alpha"

list feeds;
list headlines;
integer offset;
integer rate;

key news_pipe;

#define parcel_name() gets(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_NAME]), 0)
#define parcel_traffic() count(llGetAgentList(AGENT_LIST_PARCEL, []))
string parcel;

check_parcel() {
	string new_parcel = parcel_name();
	if(new_parcel != parcel || parcel == "") {
		alert("Welcome to " + new_parcel + ", " + llGetRegionName() + " (Population: " + (string)parcel_traffic() + ")",
			ALERT_ICON_INFO, ALERT_COLOR_NORMAL, ALERT_BUTTONS_DISMISS, ["!clear"]);
	
		parcel = new_parcel;
		setdbl("news", ["parcel"], parcel);
	}
}

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		if(argc == 1) {
			msg = PROGRAM_NAME + " add <url>: adds a URL to the news feed list\n"
				+ PROGRAM_NAME + " remove <url>: removes a URL from the news feed list\n"
				+ PROGRAM_NAME + " feeds|headlines: shows current data\n"
				+ PROGRAM_NAME + " rate <s>: seconds between each query (minimum 30, or 0 = off)\n"
				+ "\nEach feed should return only the current headline. The program will cache the most recent headline from each feed and only display the headline when an update occurs. Queries are staggered by the number of feeds, so with N feeds, a new HTTP request is generated every N/s seconds.";
		} else {
			string action = gets(argv, 1);
			string value = gets(argv, 2);
			if(action == "feeds") {
				msg = "Current feeds:\n" + concat(feeds, "\n");
			} else if(action == "headlines") {
				msg = "Latest headlines:\n" + concat(headlines, "\n");
			} else if(action == "add") {
				if(contains(feeds, value)) {
					msg = "Already subscribed to news feed " + value;
				} else {
					msg = "Added news feed " + value;
					feeds += value;
					headlines += "?";
					setdbl("news", ["feed"], jsarray(feeds));
					integer fn = count(feeds);
					set_timer("update", (float)rate / (float)fn);
				}
			} else if(action == "remove") {
				integer fi = index(feeds, value);
				if(~fi) {
					msg = "Removed news feed " + value;
					feeds = delitem(feeds, fi);
					headlines = delitem(headlines, fi);
					setdbl("news", ["feed"], jsarray(feeds));
					setdbl("news", ["headline"], jsarray(headlines));
					integer fn = count(feeds);
					integer real_rate = llRound((float)rate / (float)fn);
					integer minimum_rate = (integer)getdbl("interface", ["alert", "time"]);
					if(real_rate <= minimum_rate)
						real_rate = minimum_rate + 1;
					if(fn)
						set_timer("update", real_rate);
				} else {
					msg = "Not subscribed to news feed " + value;
				}
			
			} else if(action == "rate") {
				integer rate = (integer)value;
				
				if(rate > 0) {
					if(rate < 30)
						rate = 30;
					
					integer fn = count(feeds);
					integer real_rate = llRound((float)rate / (float)fn);
					integer minimum_rate = (integer)getdbl("interface", ["alert", "time"]);
					if(real_rate <= minimum_rate)
						real_rate = minimum_rate + 1;
					
					msg = "News feeds will now update every " + (string)(real_rate * fn) + " seconds.";
					setdbl("news", ["rate"], (string)rate);
					if(fn)
						set_timer("update", real_rate);
				} else {
					rate = 0;
					msg = "News feeds disabled.";
					set_timer("update", 0);
				}
				
				setdbl("news", ["rate"], (string)rate);
			} else if(action == "open") {
				string name = llGetObjectName();
				llSetObjectName("ARES News Ticker");
				llLoadURL(user, "See full article?", value);
				llSetObjectName(name);
			} else {
				msg = PROGRAM_NAME + ": unknown action '" + action + "'; see 'help news' for usage";
			}
		}
		
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_TIMER) {
		// echo("news timer occurred: " + m);
		if(count(feeds) == 0) {
			set_timer("update", 0);
		} else if((integer)getdbl("status", ["on"])) {
			offset = (offset + 1) % count(feeds);
			pipe_open(["notify " + PROGRAM_NAME + " headline"]);
		}
	} else if(n == SIGNAL_NOTIFY) {
		list argv = split(m, " ");
		string reason = gets(argv, 1);
		if(reason == "pipe") {
			news_pipe = ins;
			string feed = gets(feeds, offset);
			if(feed == "") {
				offset = (offset + 1) % count(feeds);
				feed = gets(feeds, offset);
			}
			http_get(feed, news_pipe, avatar);
		} else if(reason == "headline") {
			string url = gets(feeds, offset);
			string headline;
			pipe_read(ins, headline);
			
			if(~strpos(headline, "<rss") || ~strpos(headline, "<feed")) {
				string item;
				
				integer item_start = strpos(headline, "<item");
				if(~item_start) {
					item = delstring(headline, 0, item_start);
					integer item_end = strpos(item, "</item>");
					if(~item_end) {
						item = substr(item, 0, item_end);
					}
				} else {
					integer entry_start = strpos(headline, "<entry");
					if(~entry_start) {
						item = delstring(headline, 0, entry_start);
						integer entry_end = strpos(item, "</entry>");
						if(~entry_end) {
							item = substr(item, 0, entry_end);
						}
					}
				}
				
				// echo((string)strlen(headline));
				headline = "(truncated Atom or RSS entry)";
				
				integer title_start = strpos(item, "<title>");
				integer title_end = strpos(item, "</title>");
				if(~title_start && ~title_end) {
					headline = llStringTrim(substr(item, title_start + 7, title_end - 1), STRING_TRIM);
					headline = replace(headline, "\n", "");
					if(substr(headline, 0, 8) == "<![CDATA[" && substr(headline, -3, -1) == "]]>")
						headline = substr(headline, 9, -4);
					
					string bad_punctuation = "‘’“”–—";
					string good_punctuation = "''\"\"--";
					integer sbs = strlen(bad_punctuation);
					while(sbs--) {
						headline = replace(headline, substr(bad_punctuation, sbs, sbs), substr(good_punctuation, sbs, sbs));
					}
				}
				integer url_start = strpos(item, "<link>");
				integer url_end = strpos(item, "</link>");
				if(~url_start && ~url_end) {
					url = llStringTrim(substr(item, url_start + 6, url_end - 1), STRING_TRIM);
					url = replace(url, "\n", "");
				} else if(~(url_start = strpos(item, "<link href=\""))) {
					url = substr(item, url_start + 12, LAST);
					url_end = strpos(url, "\"");
					if(~url_end)
						url = substr(url, 0, url_end - 1);
				}
			} else {			
				list ni = split(headline, "\n");
				if(count(ni) > 1) {
					url = gets(ni, 1);
					headline = gets(ni, 0);
				}
			}
			
			if(headline != gets(headlines, offset)) {
				headlines = alter(headlines, [headline], offset, offset);
				setdbl("news", ["headline"], jsarray(headlines));
				alert(headline,
					ALERT_ICON_INFO,
					ALERT_COLOR_NORMAL,
					ALERT_BUTTONS_DETAILS,
					["!clear", "news open " + url]
				);
			}
			
			pipe_close([ins]);
		}
	} else if(n == SIGNAL_EVENT) {
		integer e = (integer)m;
		if(e == EVENT_TELEPORT || e == EVENT_REGION_CHANGE) {
			check_parcel();
		} else {
			echo("news event ?" + m);
		}
	
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		string s_news = llLinksetDataRead("news");
		if(s_news == JSON_INVALID) {
			s_news = "{\"feed\":[],\"headline\":[],\"rate\":0}";
			llLinksetDataWrite("news", s_news);
		}
		
		feeds = js2list(getjs(s_news, ["feed"]));
		headlines = js2list(getjs(s_news, ["headline"]));
		
		// blank entries can sometimes get created in a fresh database:
		integer mutated;
		integer blank_index;
		while(~(blank_index = index(feeds, ""))) {
			feeds = delitem(feeds, blank_index);
			headlines = delitem(headlines, blank_index);
			mutated = TRUE;
		}
		
		if(mutated) {
			s_news = setjs(s_news, ["feed"], jsarray(feeds));
			s_news = setjs(s_news, ["headline"], jsarray(headlines));
		}
		
		rate = (integer)getjs(s_news, ["rate"]);
		
		parcel = getjs(s_news, ["parcel"]);
		if(parcel == "" || parcel == JSON_INVALID) {
			parcel = parcel_name();
			s_news = setjs(s_news, ["parcel"], parcel);
			mutated = 1;
		} else {
			check_parcel();
		}
		
		if(mutated) {
			llLinksetDataWrite("news", s_news);
		}
		
		integer fn = count(feeds);
		integer real_rate = llRound((float)rate / (float)fn);
		integer minimum_rate = (integer)getdbl("interface", ["alert", "time"]);
		if(real_rate <= minimum_rate)
			real_rate = minimum_rate + 1;
		if(fn)
			set_timer("update", real_rate);
		
		hook_events([EVENT_TELEPORT, EVENT_REGION_CHANGE]);
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
