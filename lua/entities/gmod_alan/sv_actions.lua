include("core_ai.lua")

function ENT:Bonk(time, playsound)
	self.ai:RunAction("Bonk", {
		duration = time,
		silent = not playersound,
	})
end
do local ACTION = AISYS:RegisterAction("Bonk")
	function ACTION:OnStart()
		self.ent:StopMotionController()
		if not self.params.silent then
			self.ent:EmitSound("alan/bonk.wav", 100, math.random(90, 110))
		end
		self.ent.dt.bonked = true
		self.ent:GetPhysicsObject():EnableGravity(true)
		self.end_time = CurTime()+self.params.duration
	end
	function ACTION:OnSuspend(for_action, params)
		if for_action == "Bonk" then -- let's merge the two
			if not params.silent then
				self.ent:EmitSound("alan/bonk.wav", 100, math.random(90, 110))
			end
			self.end_time = self.end_time+params.duration
			return true, "I'm merging the two bonk times"
		end
	end
	function ACTION:OnUpdate()
		if CurTime() > self.end_time then
			return self.STATE_FINISHED, "My time limit is up"
		end
	end
	function ACTION:OnFinish()
		self.ent.dt.bonked = false
		self.ent:GetPhysicsObject():EnableGravity(false)
		self.ent:StartMotionController()
		self.ent:PhysWake()
	end
end

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
		self.sys:OnEvent("TargetHealed", {ply = self.params.ply})
	end
end

function ENT:Follow(ply)
	self.ai:RunAction("Follow", {
		ply = ply,
		offset = offset
	})
end
do local ACTION = AISYS:RegisterAction("Follow")
	function ACTION:OnStart()
		self.offset = self.params.offset or Vector(0)
		self.distance = self.params.distance or 100
	end
	
	function ACTION:OnResume()
		return self.STATE_INVALID, "I'm not sure what to do"
	end
	
	function ACTION:OnUpdate()
		if self.params.aim then
			self.ent.target_angle = (self.params.ply:GetPos() + self.offset - self.ent:GetPos()):Angle()
		end
		self.ent.target_position = self.params.ply:GetPos() + self.params.offset or Vector(0)
	end
end

-- core action
do local ACTION = AISYS:RegisterAction("MoveTo")
	function ACTION:OnStart()
		self.offset = self.params.offset or Vector(0)
		self.distance = self.params.distance or 100
		if self.params.aim then
			self.params.accuracy = self.params.accuracy or 0.8
		end
		self.success = false
	end
	
	function ACTION:OnResume()
		return self.STATE_INVALID, "I'm not sure what to do"
	end
	
	function ACTION:OnUpdate()
		local dir = (self.params.ent:GetPos() + self.offset - self.ent:GetPos())
		if self.params.aim then
			self.ent.target_angle = dir:Angle()
		end
		self.ent.target_position = self.params.ent:GetPos()
			+self.params.offset
				-dir:GetNormalized()*(math.min(
					self.distance,
					dir:Length()
				)*0.8)
		if self.ent:GetPos():Distance(self.params.ent:GetPos()) < self.distance and (
			not self.params.aim
			or self.ent:GetAngles():Forward():Dot(self.ent.target_angle:Forward()) > self.params.accuracy
		 ) then
			self.success = true
			return self.STATE_FINISHED, "Arrived to target"
		end
	end
	
	function ACTION:OnFinish()
		self.sys:OnEvent("TargetReached", {ent = self.params.ent})
		return true--self.success
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
		self.mover = self:RunAction("MoveTo", {
			ent = self.params.ply, 
			distance = self.ent.activeweapon.data.distance or 100, 
			offset = Vector(0,0,50),
			aim = true,
		})
	end
	
	function ACTION:OnResume(from_action, result)
		if self.finished then
			return self.STATE_FINISHED, "Shot the target until health reached"
		end
		if from_action == self.mover then
			if self.ent:GetWeaponTrace().Entity == self.params.ply then
				self.ent:FireWeapon()
			end
			if not result then
				return self.STATE_INVALID, "I couldn't follow the target"
			end
		elseif not self.params.ply:Alive() or self.params.ply:Health() <= self.params.health then
			return self.STATE_INVALID, "My target is already hurt"
		else
			self.ent:SelectWeapon(self.params.weapon)
			self.mover = self:RunAction("MoveTo", {
				ent = self.params.ply, 
				distance = self.ent.activeweapon.data.distance or 100, 
				offset = Vector(0,0,50),
				aim = true,
			})
		end
	end
	
	function ACTION:OnUpdate()
		if self.finished then
			return self.STATE_FINISHED, "Shot the target until health reached"
		end
		if self.ent:GetWeaponTrace().Entity == self.params.ply then
			self.ent:FireWeapon()
		else
			self.mover = self:RunAction("MoveTo", {
				ent = self.params.ply, 
				distance = self.ent.activeweapon.data.distance or 100, 
				offset = Vector(0,0,50),
				aim = true,
			})
		end
	end
	
	function ACTION:OnEvent(event, data, handled)
		if handled then return end
		if event_name == "TakeDamage" then
			if data.entity == self.ent and data.attacker == self.params.ply then
				return true
			end
		elseif event == "EntityTakeDamage" and data.entity == self.params.ply and data.attacker == self.ent then
			if self.params.ply:Health() <= self.params.health then
				self.finished = true
			end
			return true
		end
	end
	
	function ACTION:OnFinish()
		self.ent:SelectWeapon("none")
		self.sys:OnEvent("TargetKilled", {ply = self.params.ply})
	end
end
do local ACTION = AISYS:RegisterAction("CoreFairyBehaviour")
	function ACTION:OnUpdate()
		-- decide what to do
	end
	function ACTION:OnEvent(event_name, params, handled)
		if handled then return end
		if event_name == "TakeDamage" then
			self:RunAction("Kill", {
				ply = params.attacker,
				health = 0,
				weapon = table.Random(self.ent.weapons).data.name
			}) -- Actions are LIFO, so we do this one first
			self:RunAction("Bonk", {
				duration = 3,
			})
		end
	end
end






