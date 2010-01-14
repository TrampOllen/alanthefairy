require("core_ai")
require("modelinfo")
FAIRY_ACTIONS = {}

function ENT:Build(data)
	print("Building contraption "..data.name)
	self.build_ents = {}
	for k = 1, #data do
		local step = data[k]
		if step.type == "spawn" then
			local bounds_min, bounds_max = modelinfo.GetBounds(
			self.ai:RunAction("MoveTo", {--"MoveToVisbility", {
				ent = Entity(0),
				min_distance = 50,
				distance = 
		end
	end
	-- work in progress!
end

function ENT:Weld(ent1, ent2)
	self.ai:RunAction("TwoEntTool", {
		ent1 = ent1,
		ent2 = ent2,
		callback = function(e1, e2)
			constraint.Weld(e1, e2, 0, 0, 0, true)
		end
	})
end

do local ACTION = AISYS:RegisterAction("TwoEntTool", FAIRY_ACTIONS)
	function ACTION:OnStart()
		self.ent:SelectWeapon("tool")
		self.mover = self:RunAction("MoveTo", {--"MoveToVisibility", {
			ent = self.params.ent1,
			min_distance = 50,
			distance = 150,
			aim = true,
			aim_hit = true,
			offset = Vector(0, 0, 65),
			aim_offset = Vector(0, 0, -65)
		})
		self.stage = 1
		self.ent:SetRandomMovement(false)
	end
	function ACTION:OnResume(from_action, result)
		if not self.params.ent1:IsValid() then
			return self.STATE_INVALID, "Entity 1 is no longer valid"
		end
		if not self.params.ent2:IsValid() then
			return self.STATE_INVALID, "Entity 2 is no longer valid"
		end
		if from_action == self.mover and result then
			if self.stage == 1 then
				self.ent:ToolEffect()
				self.mover = self:RunAction("MoveTo", {--"MoveToVisibility", {
					ent = self.params.ent2,
					min_distance = 50,
					distance = 100,
					aim = true,
					aim_hit = true,
					offset = Vector(0),
				})
				self.stage = 2
			elseif self.stage == 2 then
				self.ent:ToolEffect()
				if self.params.callback then
					self.params.callback(self.params.ent1, self.params.ent2)
				end
				return self.STATE_FINISHED, "Entities have been tooled"
			end
		else
			self.sys:FinishAction(self.mover, "Recreating due to interuption")
			self.mover = self:RunAction("MoveTo", {--"MoveToVisibility", {
				ent = self.stage == 1 and self.params.ent1 or self.params.ent2,
				min_distance = 50,
				distance = 100,
				aim = true,
				aim_hit = true,
				offset = Vector(0),
			})
			self.ent:SelectWeapon("tool")
		end
	end
	function ACTION:OnFinish()
		self.ent:SelectWeapon("none")
	end
end

function ENT:Bonk(time, playsound)
	self.ai:RunAction("Bonk", {
		duration = time,
		silent = not playersound,
	})
end
do local ACTION = AISYS:RegisterAction("Bonk", FAIRY_ACTIONS)
	function ACTION:OnStart()
		self.ent:StopMotionController()
		if not self.params.silent then
			self.ent:EmitSound("alan/bonk.wav", 100, math.random(90, 110))
			self.ent:EmitSound("alan/nymph/NymphHit_0"..math.random(4)..".mp3", 100, math.random(90, 110))
		end
		self.ent.dt.bonked = true
		self.ent:GetPhysicsObject():EnableGravity(true)
		self.end_time = CurTime()+self.params.duration
	end
	function ACTION:OnSuspend(for_action, params)
		if for_action == "Bonk" then -- let's merge the two
			if not params.silent then
				self.ent:EmitSound("alan/bonk.wav", 100, math.random(90, 110))
				self.ent:EmitSound("alan/nymph/NymphHit_0"..math.random(4)..".mp3", 100, math.random(90, 110))
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
do local ACTION = AISYS:RegisterAction("Heal", FAIRY_ACTIONS)
	function ACTION:OnStart()
		self.ent:SelectWeapon("none")
		self.mover = self:RunAction("MoveTo", {
			ent = self.params.ply, 
			distance = self.params.distance or 10,
			min_distance = self.params.min_distance or 0,
			offset = Vector(0,0,65),
		})
		self.ent:SetRandomMovement(false)
		--self.last_time = nil
		self.counter = 0
		self.starting_health = self.params.ply:Health()
		self.sound = CreateSound(self.ent, "items/medcharge4.wav")
		self.sound:PlayEx(0,0)
	end
	
	function ACTION:OnResume()
		--self.last_time = nil
		self.starting_health = self.params.ply:Health()
	end
	
	function ACTION:OnUpdate()
		self.sound:ChangePitch(self.counter/self.params.health*255)
		self.sound:ChangeVolume(self.counter/self.params.health)
		self.starting_health = self.starting_health or self.params.ply:Health()
		if self.ent:GetPos():Distance(self.params.ply:GetPos()+Vector(0,0,65)) < (self.params.distance or 15) then
			self.params.ply:SetHealth(math.min(
					self.starting_health+self.counter,
					self.params.health
					--	+(CurTime()-(self.last_time or CurTime()))*self.params.rate,
					--self.params.health
			))
			if self.params.ply:Health() == self.params.health then
				return self.STATE_FINISHED, "I healed the player"
			end
			--self.last_time = CurTime()
			self.counter = self.counter + self.params.rate
		else
			self.mover = self:RunAction("MoveTo", {
				ent = self.params.ply, 
				distance = (self.params.distance or 15)-5,
				min_distance = self.params.min_distance or 0,
				offset = Vector(0,0,65),
			})
		end
	end
	
	function ACTION:OnFinish()
		self.sound:Stop()
		self.sys:OnEvent("TargetHealed", {ply = self.params.ply})
	end
end

function ENT:Follow(ply)
	self.ai:RunAction("Follow", {
		ply = ply,
		offset = offset
	})
end
do local ACTION = AISYS:RegisterAction("Follow", FAIRY_ACTIONS)
	function ACTION:OnStart()
		self.offset = self.params.offset or Vector(0)
		self.distance = self.params.distance or 100
	end
	
	function ACTION:OnResume()
		return self.STATE_INVALID, "I'm not sure what to do"
	end
	
	function ACTION:OnUpdate()
		self.ent:SetRandomMovement(true)
		if not ValidEntity(self.params.ent) then return self.STATE_INVALID, "The one I'm following is not valid" end
		local dir = (self.params.ent:GetPos() + self.offset - self.ent:GetPos())
		self.ent.target_position = self.params.ent:GetPos()
			+self.params.offset
				-dir:GetNormalized()*(math.min(
					self.distance,
					math.max(
						dir:Length(),
						self.params.min_distance or 0
					)
				)*0.8)
		self.ent.target_angle = (self.ent.target_position-self.ent:GetPos()):Angle()
	end
end

-- core action
do local ACTION = AISYS:RegisterAction("MoveTo", FAIRY_ACTIONS)
	function ACTION:OnStart()
		self.offset = self.params.offset or Vector(0)
		self.distance = self.params.distance or 100
		if self.params.aim then
			self.params.accuracy = self.params.accuracy or 0.8
		end
		self.success = false
		self.ent:SetRandomMovement(false)
	end
	
	function ACTION:OnResume()
		return self.STATE_INVALID, "I'm not sure what to do"
	end
	
	function ACTION:OnUpdate()
		if not self.ent:IsValid() then return self.STATE_INVALID, "Entity is invalid" end
		local dir = (self.params.ent:GetPos() + self.offset - self.ent:GetPos())
		if self.params.aim then
			self.ent.target_angle = (dir + (self.params.aim_offset or Vector())):Angle()
		end
		self.ent.target_position = self.params.ent:GetPos()
			+self.offset
				-dir:GetNormalized()*(math.min(
					self.distance,
					math.max(
						dir:Length(),
						self.params.min_distance or 0
					)
				)*0.8)
		if self.ent:GetPos():Distance(self.params.ent:GetPos()+self.offset) < self.distance and (
			not self.params.aim
			or self.ent:GetAngles():Forward():Dot(self.ent.target_angle:Forward()) > self.params.accuracy
		  ) and (
		 	not self.params.aim_hit
		 	or self.ent:GetWeaponTrace().Entity == self.params.ent
		  ) then
			self.success = true
			return self.STATE_FINISHED, "Arrived to target"
		end
	end
	
	function ACTION:OnFinish()
		self.sys:OnEvent("TargetReached", {ent = self.params.ent})
		return self.success
	end
end

function ENT:Kill(ply, health, weapon)
	self.ai:RunAction("Kill", {
		ply = ply, 
		health = health, 
		weapon = weapon,
	})
end

do local ACTION = AISYS:RegisterAction("Kill", FAIRY_ACTIONS)
	function ACTION:OnStart()
		if GetConVar("sbox_godmode"):GetBool() or self.params.ply.alan_god then
			return self.STATE_INVALID, "God mode is on"
		end
		self.ent:SelectWeapon(self.params.weapon)
		self.ent:SetRandomMovement(false)
		self.mover = self:RunAction("MoveTo", {
			ent = self.params.ply, 
			distance = self.ent.activeweapon.data.distance or 100,
			min_distance = self.ent.activeweapon.data.min_distance or 0,
			offset = Vector(0,0,50),
			aim = true,
			aim_hit = true,
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
			--if not result then
			--	return self.STATE_INVALID, "I couldn't follow the target"
			--end
		elseif not self.params.ply:Alive() or self.params.ply:Health() <= self.params.health then
			return self.STATE_INVALID, "My target is already hurt"
		else
			self.ent:SelectWeapon(self.params.weapon)
			self.mover = self:RunAction("MoveTo", {
				ent = self.params.ply, 
				distance = self.ent.activeweapon.data.distance or 1000, 
				min_distance = self.ent.activeweapon.data.min_distance or 0,
				offset = Vector(0,0,50),
				aim = true,
				aim_hit = true,
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
				distance = self.activeweapon and self.ent.activeweapon.data.distance or 1000,
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
			if self.params.ply:Health() <= self.params.health or self.params.health == 0 and not self.params.ply:Alive() then
				self.finished = true
			end
			return true
		end
	end
	
	function ACTION:OnFinish()
		self.ent:SelectWeapon("none")
		self.sys:OnEvent("TargetKilled", {ply = self.params.ply})
		self.ent:SetRandomMovement(true)
	end
end

do local ACTION = AISYS:RegisterAction("CoreFairyBehaviour", FAIRY_ACTIONS)
	function ACTION:OnUpdate()
		-- this is temporary. We'll make it build or whatever later on
		local closest_dist, closest = 1024
		for k,ply in pairs(player.GetAll()) do
			if ply:Alive() and ply:GetPos():Distance(self.ent:GetPos()) < closest_dist then
				closest = ply
				closest_dist = ply:GetPos():Distance(self.ent:GetPos())
			end
		end
		if closest then
			self:RunAction("Follow", {
				ent = closest,
				min_distance = 64,
				distance = 256,
				offset = Vector(0, 0, 65)
			})
		else
			self:RunAction("_wait", {duration = 5})
		end
	end
	function ACTION:OnEvent(event_name, params, handled)
		if handled then return end
		if event_name == "TakeDamage" and params.attacker ~= self.ent then
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

function ENT:Greet(ply)
	self.ai:RunAction("Greet", {
		ply = ply,
	})
end

do local ACTION = AISYS:RegisterAction("Greet", FAIRY_ACTIONS)
	function ACTION:OnStart()
		self:RunAction("MoveTo", {--"MoveToVisibility", {
			ent = self.params.ply,
			distance = 100,
		})
	end
	function ACTION:OnUpdate()
		if self.ent:GetPos():Distance(self.params.ply:GetPos()) <= 500 then
			self.ent:Respond(self.params.ply, "Hey")
			return self.STATE_FINISHED, "I greet the player"
		end
	end
end



