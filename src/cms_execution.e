note
	description: "[
				This is the execution of the cms handler request
				It builds the content to get process to render the output
			]"

class
	CMS_EXECUTION

create
	make

feature {NONE} -- Initialization

	make (req: WSF_REQUEST; res: WSF_RESPONSE; a_session_manager: like manager)
		do
			status_code := {HTTP_STATUS_CODE}.ok
			manager := a_session_manager
			request := req
			response := res
			create header.make
			controller := create {CMS_SESSION_CONTROLER}.make(request,manager) -- service.session_controller (request)
		end

feature -- Access

	manager: WSF_SESSION_MANAGER
	request: WSF_REQUEST

feature {CMS_SESSION_CONTROLER} -- Access: restricted		

	response: WSF_RESPONSE

	controller: CMS_SESSION_CONTROLER

feature -- Access: User

	user: detachable STRING
		--Returns the name of the user that is logged in
		do
			if attached {STRING} session_item ("user") as u then
				Result := u
			end
		end

	last_user_access_date: detachable DATE_TIME
		--Returns the date and time of the last user that logged in
		do
			if attached {DATE_TIME} session_item ("last_access") as dt then
				Result := dt
			end
		end

feature -- Access

	status_code: INTEGER

	header: WSF_HEADER

	logged_in: BOOLEAN


feature -- Execution

	execute
		do
			process
			terminate
		end

	login (u:like user)
		--Login a user
		do
			controller.start_session (request)
			set_user (u)
			init_last_user_access_date
		end

	logout
		--Logout a user
		do
			set_user (Void)
			controller.start_session (request)
		end

	send_user_name: detachable STRING
		--Send the name of the user that is logged in
		do
			Result:=user
		end

feature {NONE} -- Execution		

	process
		-- If the user is logged in set logged_in to be true else false
			local
				u: detachable STRING
			do
				u := user
				logged_in:=false
				if u /= Void then
					logged_in:= true
				end
			end



	frozen terminate
		--Compute response message
		local
			head:HTTP_HEADER
		do
			create head.make
			controller.session_commit (head, request)
			response.put_header_text(head.string)
		end


feature {NONE} -- Implementation

	--Set new user
	set_user (u: like user)
		do
			set_session_item ("user", u)
		end

	init_last_user_access_date
		do
			set_session_item ("last_access", (create {DATE_TIME}.make_now_utc))
		end

feature -- Access: Session		

	session_item (k: READABLE_STRING_GENERAL): detachable ANY
		do
			Result := controller.session.item (k)
		end

	set_session_item (k: READABLE_STRING_GENERAL; v: detachable ANY)
		do
			controller.session.remember (v, k)
		end

	remove_session_item (k: READABLE_STRING_GENERAL)
		do
			controller.session.forget (k)
		end

invariant

end
