note
	description : "simple application root class"
	date        : "$Date: 2013-06-19 13:31:07 -0300 (mié 19 de jun de 2013) $"
	revision    : "$Revision: 62 $"

deferred class
	APP_SERVICE

inherit
	WSF_LAUNCHABLE_SERVICE
		redefine
			initialize
		end

	WSF_ROUTED_SERVICE

	WSF_URI_HELPER_FOR_ROUTED_SERVICE

	WSF_URI_TEMPLATE_HELPER_FOR_ROUTED_SERVICE

	SHARED_EXECUTION_ENVIRONMENT
		export
			{NONE} all
		end

feature {NONE} -- Initialization

	initialize
			-- Initialize current service.
		local
			cfg: detachable READABLE_STRING_32
		do
			Precursor
			initialize_router
			build_session_manager
		end

	build_session_manager
		--Create the new session manager for the lifetime of the application, and its path is set to be the directory
		local
			dn: PATH
		do
			create dn.make_empty
			dn := dn.extended ("_storage_").extended ("_sessions_")
			create {WSF_FS_SESSION_MANAGER} session_manager.make_with_folder (dn.name)
		end

	setup_router
			-- Setup `router' and map the uri's
		local
			fhdl: WSF_FILE_SYSTEM_HANDLER
			doc: WSF_ROUTER_SELF_DOCUMENTATION_HANDLER
		do
			--Self documentation generator
			create doc.make (router)
			router.handle_with_request_methods ("/api/doc", doc, router.methods_GET)

			--mapping the various uri's
			map_uri_template_agent_with_request_methods ("/bets/{matchId}", agent place_bets, router.methods_POST)
			map_uri_template_agent_with_request_methods ("/bets/{matchId}", agent handle_bets, router.methods_GET)
			map_uri_template_agent_with_request_methods ("/matches", agent send_match_list, router.methods_GET)
			map_uri_template_agent_with_request_methods ("/login", agent send_login, router.methods_POST)
			map_uri_template_agent_with_request_methods ("/login", agent check_if_logged_in, router.methods_GET)
			map_uri_template_agent_with_request_methods ("/logout", agent logout_user, router.methods_POST)
			map_uri_template_agent_with_request_methods ("/leaderboards", agent send_leaderboard, router.methods_GET)
			map_uri_template_agent_with_request_methods ("/haveResults/{matchId}", agent send_result, router.methods_GET)
			map_uri_template_agent_with_request_methods ("/userResults/{matchId}", agent send_user_that_set_result, router.methods_GET)
			map_uri_template_agent_with_request_methods ("/results/{matchId}", agent handle_results, router.methods_GET)
			map_uri_template_agent_with_request_methods ("/results/{matchId}", agent post_results, router.methods_POST)

			--Setting the main index page
			create fhdl.make_hidden ("www")
			fhdl.set_directory_index (<<"index.html">>)
			router.handle_with_request_methods ("", fhdl, router.methods_GET)
		end

feature -- Access and constants

	address_of_files: STRING = "www/matches/"
	session_manager: WSF_SESSION_MANAGER
	cms_exe: detachable CMS_EXECUTION


feature -- Execution

	check_if_logged_in ( req: WSF_REQUEST; res: WSF_RESPONSE)
		--This function returns the username if he is logged in or else returns a blank username

		require -- from WSF_METHOD_HANDLER
			req_not_void: req /= Void
			res_not_void: res /= Void
		local
			username: STRING
			response_string:STRING
		do
			--Create cms_execution and prepare the response
			create cms_exe.make (req, res, session_manager)
			create username.make_empty
			create response_string.make_from_string ("[{%"username%" : %"")
			if attached {CMS_EXECUTION} cms_exe as ex then
				ex.execute
				--If a user is logged in, then return the username
				if ex.logged_in=true then
					if attached {STRING} ex.send_user_name as usr then
						username:=usr
					end
				end
			end
			response_string.append (username+"%"}]")
			res.put_string (response_string)
		end

	logout_user ( req: WSF_REQUEST; res: WSF_RESPONSE)
		--This function logs the user out of his session

		require -- from WSF_METHOD_HANDLER
			req_not_void: req /= Void
			res_not_void: res /= Void
		do
			--Create cms_execution and call its logout method
			create cms_exe.make (req, res, session_manager)
			if attached {CMS_EXECUTION} cms_exe as ex then
				ex.execute
				ex.logout
				ex.execute
			end
		end

	send_login (req: WSF_REQUEST; res: WSF_RESPONSE)
		--Will handle the logining in of users
		--First extract the login parameters, then get the whole directory of login parameters and compare
		--Then send or get session as is necessary

		require -- from WSF_METHOD_HANDLER
			req_not_void: req /= Void
			res_not_void: res /= Void

		local
			input_string:STRING
			l_username,l_password,user,pass: STRING
			parser:JSON_PARSER
			json_array:JSON_ARRAY
			new_json:JSON_OBJECT
			l_string:STRING
			i,flag:INTEGER
		do
			create input_string.make_empty
			create new_json.make
			create json_array.make_array
			create l_string.make_empty
			create user.make_empty
			create pass.make_empty
			create l_username.make_empty
			create l_password.make_empty
			req.read_input_data_into (input_string)
			flag:=0
			create parser.make_parser (input_string)
			--Extract parameters
			if attached {JSON_OBJECT} parser.parse as jv and parser.is_parsed then
				new_json:=jv
				l_username:=send_json_value (jv, "name")
				l_password:=send_json_value (jv, "pass")
			end
			--Read login from files
			l_string:=read_my_file_plain("login")
			if not l_string.is_empty then
				create parser.make_parser (l_string)
				if attached {JSON_ARRAY} parser.parse as jv and parser.is_parsed then
					json_array:=jv
				end
			end
			from
				i:=1
			until
				i>json_array.count
			loop
				--Compare the login from the file
				if attached {JSON_OBJECT} json_array.i_th (i) as obj then
					user:= send_json_value(obj,"username")
					pass:= send_json_value(obj,"password")
					if user.is_equal (l_username) and then pass.is_equal (l_password) then
						--Verified and return a new session here
						flag:=1
						create cms_exe.make (req, res, session_manager)
						if attached {CMS_EXECUTION} cms_exe as ex then
							ex.execute
							--Login the new user if not already logged in
							if ex.logged_in=false then
								ex.login(user)
							end
							ex.execute
						end
					end
				end
				i:=i+1
			end
			if flag=0 then
				-- Wrong credentials, so return wrong login parameters
				res.put_string ("Wrong parameters")
			end
		end

	send_match_list ( req: WSF_REQUEST; res: WSF_RESPONSE)
		--Will send the list of matches

		require -- from WSF_METHOD_HANDLER
			req_not_void: req /= Void
			res_not_void: res /= Void

		local
			input_string,path_param:STRING
			h: HTTP_HEADER
			parser: JSON_PARSER
		do
			create h.make
			create input_string.make_empty

			--Read the matches from the json object and send it to the response
			h.put_content_type_application_json
			input_string:=read_my_file_plain("matches");
			if not input_string.is_empty then
				create parser.make_parser (input_string);
			end

			h.put_content_length (input_string.count)
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (input_string)
		end

	handle_bets ( req: WSF_REQUEST; res: WSF_RESPONSE)
		--Will handle the retrieving of bets from the JSON files

		require -- from WSF_METHOD_HANDLER
			req_not_void: req /= Void
			res_not_void: res /= Void

		local
			input_string,path_param:STRING
			h: HTTP_HEADER
			parser: JSON_PARSER

		do
			create h.make
			create input_string.make_empty

			h.put_content_type_application_json
			path_param:=retrieve_matchId(req)

			input_string:=read_my_file(path_param,"bet")
			if not input_string.is_empty then
				create parser.make_parser (input_string);
			end

			h.put_content_length (input_string.count)
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (input_string)
		end


	place_bets (req: WSF_REQUEST; res: WSF_RESPONSE)
		--Will handle the adding of a bet to the set of existing bets

		require -- from WSF_METHOD_HANDLER
			req_not_void: req /= Void
			res_not_void: res /= Void

		local
			input_string:STRING
			l_string: STRING
			path_param: STRING
			id_last: INTEGER
			parser:JSON_PARSER
			json_array:JSON_ARRAY
			new_json:JSON_OBJECT
		do
			create input_string.make_empty
			create l_string.make_empty
			create json_array.make_array
			create new_json.make

			--Extract path parameters
			req.read_input_data_into (input_string)
			path_param:=retrieve_matchId(req)

			id_last:=0
			create cms_exe.make (req, res, session_manager)
			create parser.make_parser (input_string)
			if attached {JSON_OBJECT} parser.parse as jv and parser.is_parsed then
				new_json:=jv
				if attached {CMS_EXECUTION} cms_exe as ex then
					ex.execute
					--If the user is logged in, then use the user's username to place the bet
					if ex.logged_in=true then
						if attached {STRING} ex.send_user_name as usr then
							jv.replace_with_string (usr, "name")
						end
					end
				end
			end

			--Read the existing sets of bets
			l_string:=read_my_file(path_param,"bet")
			if not l_string.is_empty then
				create parser.make_parser (l_string)
				if attached {JSON_ARRAY} parser.parse as jv and parser.is_parsed then
					json_array:=jv
				end
			end
			id_last:=json_array.count
			new_json.replace_with_integer (id_last+1,"id")
			json_array.add (new_json)

			--Write the new list of bets to the file
			l_string:=json_array.representation
			write_my_file (l_string,path_param,"bet")
		end




	post_results( req: WSF_REQUEST; res: WSF_RESPONSE)
		--Post the results the user enters in the matches fields
		local
			path_param:STRING
			data:STRING
			parser:JSON_PARSER
			arr:JSON_ARRAY
			i:INTEGER
			match_id,input_string:STRING
		do
			create data.make_empty
			create arr.make_array
			path_param:=retrieve_matchId(req)
			req.read_input_data_into (data)
			create cms_exe.make (req, res, session_manager)
			create parser.make_parser (data)
			if attached {JSON_OBJECT} parser.parse as jv and parser.is_parsed then
				if attached {CMS_EXECUTION} cms_exe as ex then
					ex.execute
					--If the user is logged in, use his name to display who posted the result
					if ex.logged_in=true then
						if attached {STRING} ex.send_user_name as usr then
							jv.replace_with_string (usr, "name")
						end
					end
					data:=jv.representation
				end
			end
			--As soon as a result is entered, change the finished parameter of the match, so that the match moves down to the bottom of the list of matches
			input_string:=read_my_file_plain("matches")
			create parser.make_parser (input_string)
			if attached {JSON_ARRAY} parser.parse as jv and parser.is_parsed then
				arr:=jv
			end
			from
				i:=1
			until
				i>arr.count
			loop
				if attached {JSON_OBJECT} arr.i_th (i) as obj then
					match_id:= send_json_value(obj,"id")
					if match_id.is_equal (path_param) then
						obj.replace_with_integer (1, "finished")
					end
				end
				i:=i+1
			end
			--Write the result and the list of matches in the file
			write_my_file_plain(arr.representation,"matches")
			write_my_file(data,path_param,"result")
		end


	handle_results ( req: WSF_REQUEST; res: WSF_RESPONSE)
		--This function returns the result and the points obtained by the users
		local
			l_msg:STRING
			bet_string,result_string,user_result_string:STRING
			path_param: STRING
			leaderboard_string: STRING
			win_team,local_win_team,name,local_name: STRING
			i,j,flag:INTEGER
			team1scr,team2scr,local_team1scr,local_team2scr,local_diff,leader_points,local_points:INTEGER
			parser: JSON_PARSER
			json_result: JSON_OBJECT
			json_array: JSON_ARRAY
			leaderboard_arr: JSON_ARRAY
		do
			create win_team.make_empty
			create l_msg.make_empty
			create json_array.make_array
			create local_win_team.make_empty
			create leaderboard_arr.make_array

			path_param:=retrieve_matchId(req)
			result_string:=read_my_file(path_param,"resultfile")
			user_result_string:=read_my_file(path_param,"result")
			leaderboard_string:= read_my_file_plain("leaderboard")
			--If the result is already precomputed then simply return it
			if not result_string.is_empty then
				create parser.make_parser (result_string);
				l_msg.append (result_string)
			--If the result is not precomputed but the result has been entered, then compute the result here
			else if not user_result_string.is_empty then
				create parser.make_parser (user_result_string)
				--Obtain the results
				if attached {JSON_OBJECT} parser.parse as jv and parser.is_parsed then
					json_result:=jv
					win_team:= send_json_value(jv,"team")
					team1scr:= send_json_value(jv,"team1_score").to_integer
					team2scr:= send_json_value(jv,"team2_score").to_integer
				end
				create parser.make_parser (leaderboard_string)
				if attached {JSON_ARRAY} parser.parse as jv and parser.is_parsed then
					leaderboard_arr:=jv
				end
				--Obtain the list of bets
				bet_string:=read_my_file(path_param,"bet")
				create parser.make_parser (bet_string)
				if attached {JSON_ARRAY} parser.parse as jv and parser.is_parsed then
					json_array:=jv
				end

				from
					i:=1
				until
					i>json_array.count
				loop
					--Compare the bets with the results and store the points
					if attached {JSON_OBJECT} json_array.i_th (i) as obj then
						name:=send_json_value(obj,"name")
						local_win_team:= send_json_value(obj,"team")
						local_team1scr:= send_json_value(obj,"team1_score").to_integer
						local_team2scr:= send_json_value(obj,"team2_score").to_integer
						local_points:=0
						if local_win_team.is_equal (win_team) then
							local_diff:= (local_team1scr-team1scr).abs + (local_team2scr-team2scr).abs
							if local_diff>=10 then
								obj.replace_with_integer (0,"points")
							else
								local_points:=100-local_diff*10
								obj.replace_with_integer (local_points,"points")
							end
						else
							obj.replace_with_integer (0,"points")
						end
						--Updating leaderboards
						flag:=1
						from
							j:=1
						until
							j>leaderboard_arr.count
						loop
							--If the name already exists in the leaderboard, simply update the score, else create a new user with his new score
							if attached {JSON_OBJECT} leaderboard_arr.i_th (j) as local_obj then
								local_name:=send_json_value(local_obj,"name")
								leader_points:=0
								if attached {JSON_NUMBER} local_obj.item ("points") as pt then
									leader_points:=pt.representation.to_integer
								end
								if local_name.is_equal (name) then
									local_obj.replace_with_integer (leader_points+local_points, "points")
									flag:=0
								end
							end
							j:=j+1
						end
						if flag=1 then
							leaderboard_arr.add (obj)
						end
					end
					i:=i+1
				end
				--write the results to the file
				write_my_file (json_array.representation, path_param, "resultfile")
				write_my_file_plain(leaderboard_arr.representation,"leaderboard")
				l_msg.append (json_array.representation)
			end
			end
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_string (l_msg)
		end

	send_leaderboard ( req: WSF_REQUEST; res: WSF_RESPONSE)
		--Will send the leaderboard standings to the angular

		require -- from WSF_METHOD_HANDLER
			req_not_void: req /= Void
			res_not_void: res /= Void

		local
			input_string,path_param:STRING
			h: HTTP_HEADER
			parser: JSON_PARSER
		do
			create h.make
			create input_string.make_empty

			h.put_content_type_application_json
			input_string:=read_my_file_plain("leaderboard");
			if not input_string.is_empty then
				create parser.make_parser (input_string);
			end

			h.put_content_length (input_string.count)
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (input_string)
		end

--	send_result( req: WSF_REQUEST; res: WSF_RESPONSE)
--		local
--			path_param:STRING
--			data:STRING
--			ans:STRING
--			obj:JSON_OBJECT
--			arr:JSON_ARRAY
--			str: READABLE_STRING_GENERAL
--		do
--			create ans.make_empty
--			create arr.make_array
--			create obj.make
--			str:="yes"

--			--obj.put_string (yes, "contains")
--			path_param:= retrieve_matchId(req)
--			data:=read_my_file(path_param,"result")
--			if  not data.is_empty then
--				obj.replace_with_string (str, "contains")
--			else
--				obj.replace_with_string ("no", "contains")
--			end
--			arr.add (obj)
--			res.put_string (arr.representation)
--		end


	send_result( req: WSF_REQUEST; res: WSF_RESPONSE)
		--Sends a response indicating whether the match's result has been entered or not (for enabling and disabling of bets)
		local
			path_param:STRING
			data:STRING
			ans:STRING
		do
			create ans.make_empty
			path_param:= retrieve_matchId(req)
			ans.append ("[{ %"contains%": %"")
			data:=read_my_file(path_param,"result")
			if  not data.is_empty then
				ans.append ("yes%"}]")
			else
				ans.append ("no%"}]")
			end
			res.put_string (ans)
		end

	send_user_that_set_result ( req: WSF_REQUEST; res: WSF_RESPONSE )
		--Sends the name of the user that entered the result and the details of the result
		local
			l_msg:STRING
			input_string:STRING
			path_param: STRING
		do
			path_param:=retrieve_matchId(req)
			create l_msg.make_from_string("[")
			input_string:=read_my_file(path_param,"result")
			l_msg.append (input_string)
			l_msg.append("]")
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_string (l_msg)
		end

feature --Helper functions

	send_json_value (obj:JSON_OBJECT; key: STRING):STRING
		--Sends the string representation of the JSON value	
		do
			Result:=""
			if attached {JSON_STRING} obj.item (key) as str then
				Result:=str.unescaped_string_8
			end
		end

	read_my_file(a_string:STRING;a_head:STRING):STRING
		--Read the file and return the result in a string
		local
			my_file: PLAIN_TEXT_FILE
		do

			create my_file.make(address_of_files+a_head+"_"+a_string+".json")
			if my_file.is_empty then
				Result:=""
			else
				my_file.open_read
				my_file.read_stream (my_file.count)
				Result:=my_file.last_string
				my_file.close
			end
		end

	read_my_file_plain(a_string:STRING):STRING
		--Read the file and return the result in a string
		local
			my_file: PLAIN_TEXT_FILE
		do

			create my_file.make(address_of_files+a_string+".json")
			if my_file.is_empty then
				Result:=""
			else
				my_file.open_read
				my_file.read_stream (my_file.count)
				Result:=my_file.last_string
				my_file.close
			end
		end

	retrieve_matchId( req : WSF_REQUEST): STRING
		--Retrieve the match id from the path parameteres of the request object
		do
			if attached {WSF_STRING} req.path_parameter ("matchId") as p_id then
				Result := p_id.url_encoded_value
			else
				Result := ""
			end
		end

	write_my_file(str: STRING;a_str:STRING;a_head:STRING)
		--Write to file
		local
			my_file: PLAIN_TEXT_FILE
		do
			create my_file.make(address_of_files+a_head+"_"+ a_str + ".json")
			my_file.open_write
			my_file.put_string (str)
			my_file.close
		end

	write_my_file_plain(str: STRING;a_str:STRING)
		--Write to file
		local
			my_file: PLAIN_TEXT_FILE
		do
			create my_file.make(address_of_files+a_str+".json")
			my_file.open_write
			my_file.put_string (str)
			my_file.close
		end
	file_exists (fn: READABLE_STRING_GENERAL): BOOLEAN
		--Check if file exists or not
		local
			f: RAW_FILE
		do
			create f.make_with_name (fn)
			Result := f.exists and then f.is_readable
		end
end
