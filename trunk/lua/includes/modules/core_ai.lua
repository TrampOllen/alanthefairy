AISYS = {
	CV_Debug = CreateConVar("aisys_debug", "0"),
	debug = function(it, msg, ...)
		if true then--AISYS.CV_Debug:GetBool() then
			print((it.current_action and it.current_action.__id.." " or "")..string.format(msg, ...))
		end
	end,
	error = function(msg, ...)
		ErrorNoHalt(string.format(msg, ...))
	end
	Actions = {}
}
local dbg = AISYS.debug -- I'm lazy
local err = SISYS.error

local aient_meta = {
	RunAction = function(self, action_name, params, reason, finish_callback, parent)
		if self.current_action then
			dbg(self, "(#%s) Suspending action %s", #self.action_chain, self.current_action.__id)
			if self.current_action.OnSuspend then
				local worked, result, refuse_reason = pcall(self.current_action.OnSuspend, self.current_action.OnSuspend, action_name, params)
				if worked then
					if result then
						dbg(self, "Action %s refuses to let action %s start: %q", self.current_action.__id, action_name, refuse_reason)
						return
					end
				else
					err("Action %s:OnSuspend failed: %q", self.current_action.__id, result)
				end
			end
		end
		params = params or {}
		params.finish_callback = finish_callback
		local action = setmetatable({
			params = params,
			sys = self,
			ent = self.ent,
		}, self.ent.ai.actions[action_name] or AISYS.Actions[action_name])
		table.insert(self.action_chain, action)
		dbg(self, "(#%s) Starting action %s: %q", #self.action_chain, action_name, tostring(reason))
		if params.pre_start_callback then -- I'm aware this is a bit excessive, but we need it for the building callbacks to set the entities of TwoEntTool for the building steps
			local worked, res = pcall(params.pre_start_callback, action)
			if not worked then
				err("Action %s.params.pre_start_callback failed: %q", action.__id, res)
			end
		end
		local last, worked, result, reason = self.current_action
		self.current_action = action
		if action.OnStart then
			woked, result, reason = pcall(action.OnStart, action)
			if not worked then
				err("Action %s:OnStart failed (not starting): %q", action.__id, result)
				self.current_action = last
				return
			end
		end
		if not result then
			if params.start_callback then
				local worked, res = pcall(params.start_callback, action)
				if not worked then
					err("Action %s.params.start_callback failed: %q", action.__id, res)
				end
			end
			return action
		end
		self.current_action = last
		dbg(self, "Action %s cannot start: %q", self.current_action.__id, reason)
	end,
	Update = function(self)
		for i = 1, #self.queued_events do
			local event, handled = self.queued_events[i], false
			for k = #self.action_chain, 1, -1 do
				local action = self.action_chain[k]
				if action and action.OnEvent then
					local worked, res = pcall(action.OnEvent, action, event.name, event.params, handled)
					if worked then
						if res then
							dbg(self, "Event %s handled by action %s", event.name, action.__id)
							handled = true
						end
					else
						err("Action %s:OnEvent failed: %q", action.__id, res)
						self:FinishAction(action, "OnEvent error", true, "OnEvent error")
					end
				end
			end
		end
		self.queued_events = {}
		if self.current_action then
			local worked, result, reason
			if self.current_action.OnUpdate then
				worked, result, reason = pcall(self.current_action.OnUpdate, self.current_action)
				if not worked then
					err("Action %s:OnUpdate failed (removing): %q", self.current_action.__id, result)
					self:FinishAction(self.current_action, "OnUpdate error", false, "OnUpdate error")
				elseif CurTime() > (LAST_PRINT or 0)+1 then
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
		if not action or action._finished then return end
		reason = tostring(reason)
		dbg(self, "(#%s) Action %s finished from %s%s: %q", #self.action_chain, action.__id, tostring(by), invalid and " (says invalid)" or "", reason)
		local worked, result, res
		if action.OnFinish then
			worked, result = pcall(action.OnFinish, action)
			if not worked then
				err("Action %s:OnFinish failed with: %q", action.__id, result)
			elseif action.params.finish_callback then
				worked, res = action.param.finish_callback(action, result, reason)
				if not worked then
					err("Action %s.params.finish_callback failed: %q", action.__id, res)
				end
			end
			action.__finished = true
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
			local worked, result, reason
			if buried_action.OnResume then
				worked, result, reason = pcall(buried_action.OnResume, buried_action, action, finish_result)
				if not worked then
					err("Action %s:OnResume failed (removing): %q", buried_action, result)
					self:FinishAction(buried_action, "OnResume error", false, "OnResume error")
				elseif result == true then
					self:FinishAction(buried_action, reason, false, "Resume!")
				elseif result == false then
					self:FinishAction(buried_action, reason, true, "Resume!")
				end
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
	--SUSPEND_ALLOW = nil,
	--SUSPEND_DENY = true,
	--SUSPEND_BURY = false,
	Propagate = function(self, child, event, params)
		if self.__parent then
			if not (self.__parent.OnChildEvent and self.__parent:OnChildEvent(child.__id, child, self.__id, self, event, params)) then
				self.__parent:Propagate(child, event, params)
			end
		end
	end,
	RunAction = function(self, action_name, params, reason, finish_callback)
		return self.sys:RunAction(action_name, params, reason, finish_callback, self)
	end,
}
action_meta.__index = action_meta

function AISYS:RegisterAction(name)
	local t = setmetatable({__id = name}, action_meta)
	t.__index = t
	AISYS.Actions[name] = t
	return t
end

function AISYS:Create(ent, list)
	return setmetatable({
		action_chain = {},
		ent = ent,
		queued_events = {},
		actions = list or {}
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
