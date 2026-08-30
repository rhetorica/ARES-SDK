/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2026 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  PATH Filesystem Event Handlers
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
	
	changed(integer w) {
		if(w & CHANGED_INVENTORY) {
			#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] updating files...");
			#endif
			
			// force scan restart:
			llSetTimerEvent(0);
			scanning = FALSE;
			invoke(PROGRAM_NAME + " scan", avatar, NULL_KEY, avatar);
		}
		
		if(w & CHANGED_REGION || w & CHANGED_REGION_START) {
			if(url != "")
				llReleaseURL(url);
			url_key = llRequestURL();
			llRegionSay(C_PHASE_PROTOCOL, NULL_KEY + " reset " + DISK_LABEL);
		}
	}
	
	http_request(key id, string method, string body) {
		if(id == url_key) {
			if(method == URL_REQUEST_GRANTED) {
				url = body;
				
				// check for active connections, send updates or drop as appropriate
				list host_keys = jskeys(hosts);
				integer hi = count(host_keys);
				
				while(hi--) {
					key host = getk(host_keys, hi);
					string callback = getjs(hosts, [(string)host, 2]);
					string token = getjs(hosts, [(string)host, 0]);
					string full_url = url + "/" + token + "/";
					if(callback != "" && callback != JSON_INVALID) {
						string body = jsobject([
							"session", getjs(hosts, [(string)host, 0]),
							"message", "url",
							"args", full_url
						]);
						llHTTPRequest(callback, [HTTP_METHOD, "POST"], body);
					} else if(object_exists(host) && !is_avatar(host)) {
						tell(host, C_PHASE_PROTOCOL, token + " " + full_url);
					} else {
						disconnect(token);
					}
				}
			} else {
				echo("[" + PROGRAM_NAME + "] A URL could not be obtained. Likely there is something wrong with the region. Local storage will be unavailable until this is corrected. Type '@reset " + PROGRAM_NAME + "' to retry.");
			}
			
			llHTTPResponse(id, 200, "OK");
			
		} else {
			// string token = llGetHTTPHeader( // NOPE
			
			string path_info = llGetHTTPHeader(id, "x-path-info");
			string query_string = llGetHTTPHeader(id, "x-query-string");
			string args = jsobject(llParseStringKeepNulls(query_string, ["&", "="], [])); // a=b&c=d -> {"a":"b","c":"d"}
			
			#ifdef DEBUG
				echo("[_path] <<< " + path_info + " <?> " + query_string);
			#endif
			
			if(path_info == "" || path_info == "/") {
				// no token provided
				string action = getjs(args, ["action"]);
				if(action == "connect") {
					if(!WEB_DISCOVERABLE) {
						llHTTPResponse(id, 403, "must connect via PATH");
						return;
					}
				
					key host = llGenerateKey();
					
					string mode = getjs(args, ["mode"]);
					string token = getjs(body, ["token"]);
					string callback_url = getjs(body, ["callback"]);
					
					integer i_mode = validate_token(id, token, mode);
					
					if(i_mode) {
						string current_host = getjs(token_to_host, [token]);
						if(current_host != JSON_INVALID) {
							echo("[" + PROGRAM_NAME + "] preempting connection to " + (string)current_host);
							disconnect(token);
						}
						
						hosts = setjs(hosts, [(string)host], jsarray([
							token,
							i_mode,
							callback_url
						]));
						
						token_to_host = setjs(token_to_host, [token], host);
						
						string effective_mode = gets(["none", "ro", "rd", "rw"], i_mode);
						
						llHTTPResponse(id, 200, jsobject([
							"mode", mode,
							"url", url + "/" + token + "/",
							"version", IMPLEMENTATION,
							"label", DISK_LABEL
						]));
					} else {
						llHTTPResponse(id, 403, "credentials refused");
					}
					
				} else if(action == "disconnect") {
					string token = getjs(body, ["token"]);
					
					key host = getjs(token_to_host, [token]);
					
					if(host != JSON_INVALID) {
						disconnect(token);
						llHTTPResponse(id, 200, "OK");
					} else {
						llHTTPResponse(id, 400, "not authenticated");
					}
				
				} else {
					llHTTPResponse(id, 401, "not authenticated");
				}
			} else {
				list path = split(path_info, "/");
				string token = gets(path, 0);
				
				string host = getjs(token_to_host, [token]);
				if(host != JSON_INVALID) {
					integer mode = (integer)getjs(hosts, [host, 1]);
					
					string filename = gets(path, 1);
					
					if(filename == "") {
						// directory
						string action = getjs(args, ["action"]);
						
						if(action == "stat") {
							string file = llUnescapeURL(getjs(args, ["file"]));
							if(file == "*") {
								llHTTPResponse(id, 200, "* " + (string)strlen_byte_inline(llLinksetDataRead(DIRECTORY_CACHE)));
							} else {
								string bytes = getdbl(DIRECTORY_FILE, [file]);
								if(bytes != JSON_INVALID) {
									llHTTPResponse(id, 200, file + " " + bytes);
								} else {
									llHTTPResponse(id, 404, file + " 0");
								}
							}
						} else if(action == "write") {
							#ifdef NO_WRITE
								llHTTPResponse(id, 403, "not supported");
							#else
								llHTTPResponse(id, 500, "unimplemented");
							#endif
						} else if(action == "append") {
							#ifdef NO_WRITE
								llHTTPResponse(id, 403, "not supported");
							#else
								llHTTPResponse(id, 500, "unimplemented");
							#endif
						} else if(action == "delete") {
							if(!(mode & PERMISSION_DELETE)) {
								llHTTPResponse(id, 403, "unauthorized");
								return;
							}
							
							string file = llUnescapeURL(getjs(args, ["file"]));
							if(llGetInventoryType(file) != INVENTORY_NOTECARD) {
								llHTTPResponse(id, 404, "no file " + file);
								return;
							}
							
							llRemoveInventory(file);
							
							llHTTPResponse(id, 204, "deleted " + file);
							
							echo("[_path] deleting " + file);
							
							// notify all connected systems
							broadcast((string)id + " deleted " + file);
						} else if(action == "" || action == JSON_INVALID) {
							// reading directory contents
							string bytes = getjs(args, ["range"]);
							string dir_cache = llLinksetDataRead(DIRECTORY_CACHE);
							
							if(bytes == JSON_INVALID) {	
								if(strlen(dir_cache) > MAX_PAGE_SIZE)
									llHTTPResponse(id, 206, substr(dir_cache, 0, MAX_PAGE_SIZE - 1));
								else
									llHTTPResponse(id, 200, dir_cache);
							} else {
								string before = delstring(bytes, strpos(bytes, "-"), LAST);
								string after = delstring(bytes, 0, strpos(bytes, "-"));
								integer from = (integer)before;
								integer to = (integer)after;
								if(to < from)
									llHTTPResponse(id, 500, "bad range " + (string)from + "-" + (string)to);
								else
									llHTTPResponse(id, 206, substr(dir_cache, from, to));
							}
						} else {
							llHTTPResponse(id, 500, "unsupported action " + action);
						}
						
					} else {
						// file
						string bytes = getjs(args, ["range"]);
						string fr = getdbl(DIRECTORY_FILE, [filename]);
						integer from;
						integer to;
						if(fr == JSON_INVALID) {
							llHTTPResponse(id, 404, "no file " + filename);
							return;
						} else if(bytes == JSON_INVALID) {
							from = 0;
							to = (integer)fr; // get length
						} else {
							string before = delstring(bytes, strpos(bytes, "-"), LAST);
							string after = delstring(bytes, 0, strpos(bytes, "-"));
							from = (integer)before;
							to = (integer)after;
							integer flen = (integer)fr; // get length
							if(to > flen - 1)
								to = flen - 1;
						}
						
						if(to - from >= MAX_PAGE_SIZE)
							to = from + MAX_PAGE_SIZE - 1;
						
						if(to < from)
							llHTTPResponse(id, 500, "bad range " + (string)from + "-" + (string)to);
						else if(to == 0 && bytes == JSON_INVALID)
							llHTTPResponse(id, 200, "empty file " + filename); // empty file
						else {
							// echo("requesting read: " + filename + " from " + (string)from + " to " + (string)to);
							
							read_ks = setjs(read_ks, [
								llGetNotecardLine(filename, 0)
							], jsarray([
								filename, 0, 0, id, from, to, ""
							]));
						}
					}
				} else {
					llHTTPResponse(id, 401, "not authenticated");
				}
			}
		}
	}
	
	timer() {
		// main operation of scan -- we must read every single notecard to achieve readiness
		
		string filename = llGetInventoryName(INVENTORY_NOTECARD, scan_progress++);
		if(filename != "") {
			integer type = llGetInventoryType(filename);
			key asset = llGetInventoryKey(filename);
			string stored_asset = getdbl(DIRECTORY_META, [filename]);
			
			if(stored_asset != asset) {
				if(scan_changes == "" && stored_asset == JSON_INVALID)
					scan_changes = "new " + filename;
				else
					scan_changes = "update";
				
				llSetMemoryLimit(0x0fffe);
				llSetMemoryLimit(0x10000);
				setdbl(DIRECTORY_FILE, [filename], "0"); // empty length to start
				
				llSetMemoryLimit(0x0fffe);
				llSetMemoryLimit(0x10000);
				setdbl(DIRECTORY_META, [filename], asset);
				
				// queue the file for scanning:
				// echo("scanning " + filename);
				scan_ks = setjs(scan_ks, [llGetNotecardLine(filename, 0)], jsarray([
					filename,
					0, // current line
					0 // bytes so far
				]));
				
				llSetTimerEvent(2); // dataserver() will resume it sooner
			}
		}
		
		if(scan_progress >= llGetInventoryNumber(INVENTORY_NOTECARD)) {
			// that was the last file
			llSetTimerEvent(0);
			
			if(scanning == TRUE) {
				scanning = 2; // done
				
				if(scan_ks == "{}")
					after_scan();
			}
		}
	}
	
	dataserver(key q, string m) {
		string sr = getjs(scan_ks, [q]);
		if(sr != JSON_INVALID) {
			string filename = getjs(sr, [0]);
			integer line = (integer)getjs(sr, [1]);
			integer bytes = (integer)getjs(sr, [2]);
			// echo("checking size of " + filename + " from line " + (string)line);
			
			while(m != EOF && m != NAK) {
				bytes += strlen_byte_inline(m) + (line > 0); // add linebreak
				++line;
				m = llGetNotecardLineSync(filename, line);
				
				// health check:
				llSetMemoryLimit(0x0fffe);
				llSetMemoryLimit(0x10000);
			}
			
			scan_ks = setjs(scan_ks, [q], JSON_DELETE);
			if(m == NAK) {
				q = llGetNotecardLine(filename, line);
				// echo("ds restart - " + filename);
				scan_ks = setjs(scan_ks, [q], jsarray([filename, line, bytes]));
			} else {
				// file read is complete
				setdbl(DIRECTORY_FILE, [filename], (string)bytes);
				// echo("ds store - " + filename);
				// echo("size of " + filename + ": " + (string)bytes + " bytes");
				llSetTimerEvent(0.1);
				if(scan_ks == "{}") {
					if(scanning != 1)
						after_scan();
				}
			}
			
			return;
		}
		
		string rr = getjs(read_ks, [q]);
		if(rr != JSON_INVALID) {
			string filename = getjs(rr, [0]);
			integer line = (integer)getjs(rr, [1]);
			integer bytes = (integer)getjs(rr, [2]);
			integer start = (integer)getjs(rr, [4]);
			integer end = (integer)getjs(rr, [5]);
			integer target_length = end - start + 1;
			string loaded = (getjs(rr, [6]));
			
			// echo("doing read: " + filename + " from " + (string)start + " to " + (string)end);
			
			while(m != EOF && m != NAK) {
				/* Note on Unicode Limitations
				
					Because we have no safe way of getting a byte substring, we will generally tend toward extracting too much text during the process. Hopefully this implementation will at most drop 1-2 extra bytes from the end of the request to prevent the last character from being damaged. It is up to the receiving client to recognize the response was incomplete (using information from stat) and to seek more data.
				*/
				if(line > 0)
					m = "\n" + m;
				
				integer new_bytes = bytes + strlen_byte_inline(m);
				// echo("adding bytes " + (string)new_bytes);
				if(new_bytes > start) {
					if(bytes < start) { // read window began within the message
					    if(new_bytes > end) { // entire read window is in this line
							loaded += substr(m, start - bytes, end - bytes);
						} else { // read window extends past the end of this line
							loaded += substr(m, start - bytes, LAST);
						}
					} else if(new_bytes > end) { // end of the read window falls within this line
						loaded += substr(m, 0, end - bytes);
					} else { // this line falls entirely within the read window
						loaded += m;
					}
				}
				
				// echo("chars loaded: <<" + loaded + ">>");
				
				bytes = new_bytes;
				if(strlen_byte_inline(loaded) >= target_length) {
					// read is complete:
					jump done_read;
				}
				++line;
				m = llGetNotecardLineSync(filename, line);
			}
			@done_read;
			
			read_ks = setjs(read_ks, [q], JSON_DELETE);
			key http_id = getjs(rr, [3]);
			
			if(bytes >= end) {
				integer loaded_length = strlen_byte_inline(loaded);
				if(loaded_length > target_length)
					loaded = strleft_byte(loaded, target_length);
				
				// echo("chars selected for final output: <<" + loaded + ">>");
				
				integer file_length = (integer)getdbl(DIRECTORY_FILE, [filename]);
				integer return_code = 206;
				if(file_length == end + 1 && start == 0)
					return_code = 200;
				llHTTPResponse(http_id, return_code, loaded);
			} else if(bytes < end) {
				q = llGetNotecardLine(filename, line);
				read_ks = setjs(read_ks, [q], jsarray([filename, line, bytes, http_id, start, end, (loaded)]));
			}
		}
	}
	
	