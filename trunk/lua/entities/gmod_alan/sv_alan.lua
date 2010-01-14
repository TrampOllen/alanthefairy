require("socket")
local url = require("socket.url")

-- Get the cookie first!
local requests = {}
BOT_REQUESTS = requests
local cookies = {}

local function DoRequest(t)
	t.sock = socket.connect("www.a-i.com", 80)
	if not t.sock then
		error("Unable to connect to www.a-i.com!", 2)
	return end
	t.sock:send("GET http://www.a-i.com/alan1/webface1_ctrl.asp?gender="..t.gender.."&name="..url.escape(t.name).."&question="..url.escape(t.question).." HTTP/1.1\n")
	t.sock:send("Host: www.a-i.com\n")
	t.sock:send("User-Agent: GMod10\n")
	t.sock:send("Cookie: "..cookies[t.uniqueid].."\n")
	t.sock:send("Connection: Close\n")
	t.sock:send("\n")
	table.insert(requests, t)
end
local function LodgeRequest(name, gender, uniqueid, question, callback)
	--print(name, gender, uniqueid, question, callback)
	local request = {
		name = name,
		gender = gender,
		uniqueid = uniqueid or 0,
		question = question,
		callback = callback,
		in_header = true,
		header = "",
	}
	if not cookies[uniqueid or 0] then
		local cookie_request = {
			sock = socket.connect("www.a-i.com", 80),
			uniqueid = uniqueid,
			following_request = request,
			in_header = true,
			header = "",
			for_cookie = true,
		}
		if not cookie_request.sock then
			error("Unable to connect to www.a-i.com!", 2)
		return end
		cookie_request.sock:send("GET /alan1/webface1.asp HTTP/1.1\n")
		cookie_request.sock:send("Host: www.a-i.com\n")
		cookie_request.sock:send("User-Agent: GMod10\n")
		cookie_request.sock:send("Connection: Close\n")
		cookie_request.sock:send("\n")
		table.insert(requests, cookie_request)
	return end
	DoRequest(request)
end
local function ParseHeader(header)
	local headers = {}
	for key, value in string.gmatch(string.gsub(header, "HTTP/1.1 200 OK\r\n", ""), "([^:]+):%s*([^\n\r]*)%s*") do
		headers[string.lower(key)] = value
	end
	return headers
end
local function ParseRequest(request)
	if request.for_cookie then
		cookies[request.uniqueid] = request.header_data["set-cookie"]
		if request.following_request then
			DoRequest(request.following_request)
		end
	return end
	for answer in string.gmatch(request.body or "", "<option>answer = ([^\n]*)") do
		local worked, res = pcall(request.callback, request.uniqueid, request.question, answer, request.name, request.gender)
		if not worked then
			ErrorNoHalt(string.format("Callback for answer %q failed: %q!", answer, res))
		end
	end
end
hook.Add("Think", "Alan", function()
	for id, request in ipairs(requests) do
		repeat
			request.sock:settimeout(0)
			data, err = request.sock:receive(1)
			if not data then
				if err == "closed" then
					table.remove(requests, id)
					ErrorNoHalt("Socket for request ("..request.uniqueid..") closed unexpectedly!")
				end
			elseif request.in_header then
				request.header = request.header..data
				if string.match(request.header, "\r\n\r\n$") then
					request.in_header = false
					request.header_data = ParseHeader(request.header)
					if (tonumber(request.header_data["content-length"]) or 0) == 0 then
						ParseRequest(request)
						table.remove(requests, id)
					end
					request.body = ""
				end
			else
				request.body = request.body..data
				if #request.body == tonumber(request.header_data["content-length"]) then
					ParseRequest(request)
					table.remove(requests, id)
					break
				end
			end
		until not data
	end
end)

function ENT:Chat(uniqueid, question, name, callback)
	LodgeRequest(name, "unknown", uniqueid, question, callback)
end

function ENT:SayToPlayer(ply, text)
	umsg.Start( "Alan:ToPlayer" )
		umsg.Entity( ply )
		umsg.String( ply:UniqueID() )
		umsg.String( text )
	umsg.End()
end

function ENT:Respond(ply, text)
	self.dt.isthinking = true
	self:Chat(ply:UniqueID(), text, GetConVar("alan_name"):GetString(), function(id, question, result, name, gender) 
		self:SayToPlayer(ply, result)
		self.dt.isthinking = false
		hook.Call("AlanChat", gmod.GetGamemode(), self, result, id)
	end)
end

function ENT:Say(text)
	umsg.Start( "Alan:Respond" )
		umsg.String( text )
	umsg.End()
end