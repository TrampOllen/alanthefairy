include("core_ai.lua")
do local ACTION = AISYS:RegisterAction("RollTo")
	function ACTION:OnUpdate()
		self.ent:GetPhysicsObject():ApplyForceCenter(
			(self.params.ent:GetPos()-self.ent:GetPos()):GetNormalized()*self.params.speed*FrameTime()
		)
		if self.ent:GetPos():Distance(self.params.ent:GetPos()) < (self.params.distance or 100) then
			return self.STATE_FINISHED, "I arrived at my target"
		end
	end
	function ACTION:OnResume()
		self.failure = true
		if not self.params.ent:IsValid() then
			return self.STATE_INVALID, "My target is no longer valid"
		end
		return self.STATE_INVALID, "I'm not sure what to do"
	end
	function ACTION:OnFinish()
		return not self.failure
	end
end
do local ACTION = AISYS:RegisterAction("AttackPlayer")
	function ACTION:OnStart()
		self.roll_to = self:RunAction("RollTo", {
			ent = self.params.player,
			distance = 50,
			speed = 10000,
		})
	end
	function ACTION:OnResume(from_action, result)
		if from_action == self.roll_to and result and not self.failure then
			self.params.player:Kill()--TakeDamage(100, self.ent)
			self.success = true
			return self.STATE_FINISHED, "I attacked the player"
		end
		return self.STATE_INVALID, "I'm not sure what to do"
	end
	function ACTION:OnEvent(event, data)
		if event == "PlayerDeath" and data.ply == self.params.player then
			print("Target just died!")
			self.failure = true
			self.sys:FinishAction(self.roll_to, "Target is dead")
			return self.STATE_INVALID, "My target died"
		end
	end
	function ACTION:OnFinish()
		return not self.failure
	end
end
do local ACTION = AISYS:RegisterAction("Flee")
	function ACTION:OnResume(from_action, result)
		return self.STATE_INVALID, "I'm not sure what to do"
	end
	function ACTION:OnUpdate()
		local closest_dist, closest = math.huge
		for k,ply in pairs(player.GetAll()) do
			if ply:GetPos():Distance(self.ent:GetPos()) < closest_dist then
				closest = ply
				closest_dist = ply:GetPos():Distance(self.ent:GetPos())
			end
		end
		self.ent:GetPhysicsObject():ApplyForceCenter(
			(self.ent:GetPos()-closest:GetPos()):GetNormalized()*self.params.speed*FrameTime()
		)
		if not closest or closest_dist > self.params.distance then
			return true, "I'm at a safe distance"
		end
	end
end
do local ACTION = AISYS:RegisterAction("AttackRandomPlayer")
	function ACTION:OnStart()
		local closest_dist, closest = self.params.max_distance
		for k,ply in pairs(player.GetAll()) do
			if ply:Alive() and ply:GetPos():Distance(self.ent:GetPos()) < closest_dist then
				closest = ply
				closest_dist = ply:GetPos():Distance(self.ent:GetPos())
			end
		end
		if closest then
			self:RunAction("AttackPlayer", {
				player = closest
			})
		else
			return true, "No player nearby"
		end
	end
	function ACTION:OnResume(from_action)
		if from_action == "AttackPlayer" then
			return self.STATE_FINISHED, "I finished my attack on the player"
		end
		return self.STATE_INVALID, "I'm not sure what to do"
	end
end
do local ACTION = AISYS:RegisterAction("CoreRollingBehaviour")
	function ACTION:OnStart()
		self.random_attack = self:RunAction("AttackRandomPlayer", {
			max_distance = 1024*2
		})
	end
	function ACTION:OnResume(from_action, result)
		if from_actiton == self.random_attack then
			-- find a new player to attack
			self.random_attack = self:RunAction("AttackRandomPlayer", {
				max_distance = 1024*2
			})
		elseif from_action == self._wait then
			self:RunAction("AttackRandomPlayer", {
				max_distance = 1024*2
			})
		end
	end
	function ACTION:OnUpdate()
		self._wait = self:RunAction("_wait", {duration = 5})
	end
	function ACTION:OnEvent(event, params)
		if event == "TakeDamage" then
			self:RunAction("Flee", {
				distance = 1024,
				speed = 10000,
			})
		end
	end
end

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:SpawnFunction(ply, trace)
	local ent = ents.Create("aitest")
	ent:SetPos(trace.HitPos+Vector(0,0,50))
	ent:Spawn()
	return ent
end

function ENT:Initialize()
	self:SetModel("models/dav0r/hoverball.mdl")
	
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInit( SOLID_VPHYSICS )  
	local physicsobject = self:GetPhysicsObject()
		
	if (physicsobject:IsValid()) then
		physicsobject:Wake()
	end
	self.ai = AISYS:Create(self)
	self.ai:RunAction("CoreRollingBehaviour")

	hook.Add("DoPlayerDeath", "aitest"..self:EntIndex(), function(ply, attacker, dmginfo)
		self.ai:OnEvent("PlayerDeath", {
			ply = ply,
			attacker = atacker,
			dmginfo = dmginfo,
		})
	end)
end

function ENT:Think()
	self.ai:Update()
end

function ENT:OnTakeDamage(dmginfo)
	self.ai:OnEvent("TakeDamage", {
		dmginfo = dmginfo
	})
end

function ENT:OnRemove()
	hook.Remove("DoPlayerDeath", "aitest"..self:EntIndex())
end