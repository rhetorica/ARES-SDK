/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  LSLisp System Module
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
#include <lslisp.lsl>
#define CLIENT_VERSION "0.2.5"
#define CLIENT_VERSION_TAGS "lang " + INTERPRETER_VERSION

integer file_offset;
integer file_length;
key file_outs;
key file_user;
key file_pipe;
string file_name;
string file_unit;

#define FILE_STEP_SIZE 10

main(integer src, integer n, string m, key e_outs, key e_ins, key e_user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		if(argc == 1) {
			print(e_outs, e_user, "Syntax: @" + PROGRAM_NAME + " <filename>");
		} else {
			// set aside session info for when we have data to output:
			file_outs = e_outs;
			file_user = e_user;
			parse_queue = v_names = v_values = interrupted_stack = [];
			interrupt = "";
			
			// always needed for file loading:
			file_name = gets(argv, 1);
			file_unit = "";
			file_offset = file_length = NOWHERE;
			file_open(file_pipe = llGenerateKey(), file_name);
			
			// prevent job from ending while loading file:
			task_begin(file_pipe, file_name);
		}
	} else if(n == SIGNAL_NOTIFY) {
		if(m == PROGRAM_NAME + " file") {
			if(e_ins == file_pipe) {
				// copy contents of LSD file_pipe into local variable:
				string file_buffer;
				pipe_read(file_pipe, file_buffer);
				
				integer read_length = FILE_STEP_SIZE;
				if(file_unit == "b") read_length *= FILE_PAGE_LENGTH;
				
				if(file_length == NOWHERE) {
					// haven't loaded file length yet
					list stat = split(file_buffer, " ");
					file_length = (integer)gets(stat, 0);
					file_unit = gets(stat, 1);
					file_offset = 0;
					// for notecards this is measured as 256 * (number of lines),
					// NOT actual character count
				} else {
					file_offset += read_length;
				}
				
				if(read_length + file_offset > file_length)
					read_length = file_length - file_offset;
				
				if(file_offset == 0) {
					if(file_length > 0) {
						// start reading file
						file_read(file_pipe, file_name, (string)file_offset + " " + (string)read_length);
					} else {
						// file not found or file empty
						print(file_user, file_user, "No file: " + file_name);
						file_close(file_pipe);
						
						// job can now end:
						task_end(file_pipe);
					}
				} else {
					// got length earlier, so this must be file data
					parse_queue += ["\n"] + tokenize(file_buffer);
					
					// is there more file?
					if(file_offset < file_length) {
						// get next section
						// move forward to next page:
						file_read(file_pipe, file_name, (string)file_offset + " " + (string)read_length);
					} else {
						// reached end of file
						file_close(file_pipe);
						
						user = file_user;
						outs = file_outs;
						
						string prog = parse(parse_queue);
						
						list output = execute([stack_frame(prog, [], NOWHERE, "{}", 0, NOWHERE)]);
						
						string msg;
						
						if(interrupt) {
							msg = "-- Interrupted!";
							
						} else {
							msg = concat(output, " ");
						}
						
						print(file_user, file_outs, msg);
						
						// job can now end:
						// task_end(file_pipe);
					}
				}
			} else {
				echo("[" + PROGRAM_NAME + "] file data offered via unexpected pipe: " + (string)e_ins);
			}
		}
	} else if(n == SIGNAL_INIT) {
		// print(e_outs, e_user, "[" + PROGRAM_NAME + "] init event; nothing to do");
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
