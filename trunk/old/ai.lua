local ACTION = FAIRY:RegisterAction("Weld")
function ACTION:OnStart()
	self:SelectWeapon("weapon_toolgun") -- This will be implemented internally
	self.stage = 1 -- this is so we can store our 'stage'. Only actions that progress will need this
	self.ent:RunAction("MoveToVisibility", {ent = self.params.ent1}) -- This will create a Locomotion action to 'move' to the given entity.
	-- Because it's an action, /this/ action will be suspended
	-- Stages:
		-- 1: Move to prop 1
		-- 2: Aim for prop 1
		-- 3: Fire toolgun
		-- 4: Move to prop 2
		-- 5: Aim for prop 2
		-- 6: Fire toolgun
end
function ACTION:OnSuspend(for_action)
	-- meaning this is called for line 7
end
function ACTION:OnResume(from_action, result)
	if not self.params.ent1:IsValid() then
		return false, "Entity 1 has become invalid."
	end
	if not self.params.ent2:IsValid() then
		return false, "Entity 2 has become invalid."
	end
	if self.stage == 1 then
		if from_action == "MoveToVisibility" and not result.success then
			return self.STATE_FAILURE, nil, "I couldn't move to Entity 1"
		end
		self.ent:RunAction("AimAt", {ent = self.params.ent1})
		self.stage = 2
	elseif self.stage == 2 then
		if from_action == "AimAt" and not result.success then
			-- I don't think this is too bad. Weld them anyway
		end
		self.stage = 3
	elseif self.stage == 3 then
		self.ent:RunAction("MoveToVisibility", {ent = self.params.ent2})
		self.stage = 4
	elseif self.stage == 4 then
		if from_action == "MoveToVisibility" and not result.success then
			return self.STATE_FAILURE, "I couldn't move to Entity 2"
		end
		self.ent:RunAction("AimAt", {ent = self.params.ent2})
		self.stage = 5
	elseif self.stage == 5 then
		if from_action == "AimAt" and not result.success then
			-- I don't think this is too bad. Weld them anyway
		end
		self.ent:ToolEffect()
		constraint.Weld(self.params.ent1, self.params.ent2, 0, 0, 0, false)
		return self.STATE_FINISHED
	end
	return self.STATE_CONTINUE
end
