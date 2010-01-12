include("core_ai.lua")

function ENT:Heal(ply, health, rate)
	self.ai:RunAction("Heal", {
		ply = ply, 
		health = health, 
		rate = rate
	})
end

do local ACTION = AISYS:RegisterAction("Heal")
	function ACTION:OnStart()
		self.number = 0
		self.current_health = self.params.ply:Health()
		self:RunAction("Follow", {
			ply = self.params.ply, 
			offset = Vector(0,0,50)
		})
	end
	
	function ACTION:OnResume()
		self.current_health = self.params.ply:Health()
	end
	
	function ACTION:OnUpdate()
		if self.ent:GetPos():Distance(self.params.ply:GetPos()) < 10 then
			self.number = self.number + self.params.rate
			self.params.ply:SetHealth(self.current_health + self.number)
			if self.params.ply:Health() >= self.params.health then
				return self.STATE_FINISHED, "Sucessfully healed player"
			end
		end
	end
	
	function ACTION:OnFinish()
		self.ent.ai:OnEvent("TargetHealed", {ply = self.params.ply})
	end
end

function ENT:Follow(ply)
	self.ai:RunAction("Follow", {
		ply = ply, 
		distance = distance, 
		offset = offset
	})
end

do local ACTION = AISYS:RegisterAction("Follow")
	function ACTION:OnStart()
		self.offset = self.params.offset or Vector(0)
		self.distance = self.params.distance or 100
	end
	
	function ACTION:OnUpdate()
		self.ent.target_angle = self.params.aim and  (self.params.ply:GetPos() + self.offset - self.ent:GetPos()):Angle()
		if self.ent:GetPos():Distance(self.params.ply:GetPos()) < self.distance then
			return true, "Arrived to target"
		end
		self.ent.target_position = self.params.ply:GetPos() + self.params.offset or Vector(0)
	end
	
	function ACTION:OnFinish()
		self.ent.ai:OnEvent("TargetReached", {ply = self.params.ply})
	end
end

function ENT:Kill(ply, health, weapon)
	self.ai:RunAction("Kill", {
		ply = ply, 
		health = health, 
		weapon = weapon,
	})
end

do local ACTION = AISYS:RegisterAction("Kill")
	function ACTION:OnStart()
		self.ent:SelectWeapon(self.params.weapon)
		self:RunAction("Follow", {
			ply = self.params.ply, 
			distance = self.ent.activeweapon.data.distance or 100, 
			offset = Vector(0,0,50),
			aim = true,
		})
	end
	
	function ACTION:OnUpdate()
		if self.ent:GetWeaponTrace().Entity == self.params.ply then
			self.ent:FireWeapon()
			return true, "Shooting target"
		end
	end
	
	function ACTION:OnEvent(event, data)
		if event == "EntityTakeDamage" and data.entity == self.params.ply and data.attacker == self.ent then
			if not data.entity:Alive() and self.health == 0 then
				return self.STATE_FINISHED, "Killed the Target"
			end
			if self.params.ply:Health() <= self.params.health then
				return self.STATE_FINISHED, "Shot the target until health reached"
			end
		end
	end
	
	function ACTION:OnFinish()
		self.ent.ai:OnEvent("TargetKilled", {ply = self.params.ply})
	end
end