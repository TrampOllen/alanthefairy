AISYS = {
	CV_Debug = CreateConVar("aisys_debug", "0"),
	debug = function(it, msg, ...)
		if true then--AISYS.CV_Debug:GetBool() then
			print((it.current_action and it.current_action.__id.." " or "")..string.format(msg, ...))
		end
	end,
	Actions = {}
}
local dbg = AISYS.debug -- I'm lazy

local aient_meta = {
	RunAction = function(self, action_name, params, reason, parent)
		if self.current_action then
			dbg(self, "(#%s) Suspending action %s", #self.action_chain, self.current_action.__id)
			if self.current_action.OnSuspend then
				self.current_action:OnSuspend(action, params)
			end
		end
		local action = setmetatable({
			params = params,
			sys = self,
			ent = self.ent,
		}, self.ent.ai.actions[action_name] or AISYS.Actions[action_name])
		table.insert(self.action_chain, action)
		dbg(self, "(#%s) Starting action %s: %q", #self.action_chain, action_name, tostring(reason))
		local last, result, reason = self.current_action
		self.current_action = action
		if action.OnStart then
			result, reason = action:OnStart()
		end
		if not result then
			return action
		end
		self.current_action = last
		dbg(self, "Action %s cannot start: %q", self.current_action.__id, reason)
	end,
	Update = function(self)
		for i = 1, #self.queued_events do
			local event, handled = self.queued_events[i], false
			for k, action in pairs(self.action_chain) do
				if action.OnEvent then
					handled = handled or action:OnEvent(event.name, event.params, handled)
				end
			end
		end
		self.queued_events = {}
		if self.current_action then
			local result, reason
			if self.current_action.OnUpdate then
				result, reason = self.current_action:OnUpdate()
				if CurTime() > (LAST_PRINT or 0)+1 then
					LAST_PRINT = CurTime()
					dbg(self, "(#%s) Running update of %s = %q!", #self.action_chain, self.current_action.__id, tostring(result))
				end
			end
			if result == true or not self.current_action.OnUpdate then
				self:FinishAction(self.current_action, reason, false, "Update!")
			elseif result == false then
				self:FinishAction(self.current_action, reason, true, "Update!")
			end
		else
			-- oh shit, nothing to do. What now?
			-- This shoudn't happen!
			-- The core entity behaviour action will decide what should happen in an idle state
		end
	end,
	FinishAction = function(self, action, reason, invalid, by)
		dbg(self, "(#%s) Action %s finished from %s%s: %q", #self.action_chain, action.__id, tostring(by), invalid and " (says invalid)" or "", tostring(reason))
		local result
		if action.OnFinish then
			result = action:OnFinish()
		end
		if action == self.current_action then
			table.remove(self.action_chain, #self.action_chain)
			self:_ResumeBuriedAction(action, result)
		else
			for k = 1, #self.action_chain do
				if action == self.action_chain[k] then
					table.remove(self.action_chain, k)
					break
				end
			end
		end
	end,
	_ResumeBuriedAction = function(self, action, finish_result)
		local buried_action = self.action_chain[#self.action_chain]
		if buried_action then
			dbg(self, "(#%s) Resuming action %s", #self.action_chain, buried_action.__id)
			self.current_action = buried_action
			local result, reason
			if buried_action.OnResume then
				result, reason = buried_action:OnResume(action, finish_result)
			end
			if result == true then
				self:FinishAction(buried_action, reason, false, "Resume!")
			elseif result == false then
				self:FinishAction(buried_action, reason, true, "Resume!")
			end
		else
			-- er...
		end
	end,
	OnEvent = function(self, event_name, params)
		dbg(self, "Event %s called", event_name)
		table.insert(self.queued_events, {name = event_name, params = params})
	end,
}
aient_meta.__index = aient_meta
local action_meta = {
	STATE_FINISHED = true,
	STATE_CONTINUE = nil,
	STATE_INVALID = false,
	Propagate = function(self, child, event, params)
		if self.__parent then
			if not (self.__parent.OnChildEvent and self.__parent:OnChildEvent(child.__id, child, self.__id, self, event, params)) then
				self.__parent:Propagate(child, event, params)
			end
		end
	end,
	RunAction = function(self, action_name, params, reason)
		return self.sys:RunAction(action_name, params, reason, self)
	end,
}
action_meta.__index = action_meta

function AISYS:RegisterAction(name)
	local t = setmetatable({__id = name}, action_meta)
	t.__index = t
	AISYS.Actions[name] = t
	return t
end

function AISYS:Create(ent)
	return setmetatable({
		action_chain = {},
		ent = ent,
		queued_events = {},
		actions = {}
	}, aient_meta)
end

do local ACTION = AISYS:RegisterAction("_wait")
	function ACTION:OnStart()
		self.end_time = CurTime()+self.params.duration
	end
	function ACTION:OnUpdate()
		if CurTime() > self.end_time then
			return self.STATE_FINISHED, "Waiting time was complete"
		end
	end
	function ACTION:OnResume()
		if CurTime() > self.end_time then
			return self.STATE_INVALID, "My waiting time has passed"
		end
	end
end
