require("core_ai")
require("modelinfo")
FAIRY_ACTIONS = {}

function ENT:Build(data)
	self.ai:RunAction("Build", {
		contraption = data
	})
end
do local ACTION = AISYS:RegisterAction("Build", FAIRY_ACTIONS)
	function ACTION:OnStart()
		self.ent.build_ents = {}
		self.params.contraption.name = type(self.params.contraption.name) == "string" and self.params.contraption.name or "Unnamed Contraption"
		MsgAll("Alan: Building contraption "..self.params.contraption.name.." by "..tostring(self.params.contraption.author))
		self.current_actions = {}
		self.build_origin = Vector(0,0,0)
		-- We need to use the pathfinding to find a blank space big enough to build in
		self.step = 0
	end
	function ACTION:OnResume(action, state, result, reason)
		if self.current_actions[action] then
			self.current_actions[action] = nil
			if not result then
				return self.STATE_INVALID, action.__id.." failed"
			elseif state == action.STATE_INVALID then
				self.step = self.step-1
			end
		end
	end
	function ACTION:OnUpdate()
		self.step = self.step+1
		local step = self.params.contraption[self.step]
		if not step then
			return self.STATE_FINISHED, "All steps complete"
		end
		if step.type == "spawn" then
			local distance 
			if step.model then
				step.model = tostring(step.model)
				util.PrecacheModel(step.model)
				local model_id = modelinfo.GetIndex(step.model)
				if not model_id or model_id == 0 then
					self:StopBuild("Invalid model %q", tostring(step.model))
					return
				end
				local bounds_min, bounds_max = modelinfo.GetBounds(model_id)
				distance = math.max(bounds_min:Length(), bounds_max:Length())
			else
				distance = 80 -- Good value?
			end
			self.current_actions[self:RunAction("MoveToWorld", {--"MoveToWorldVisbility", {
				min_distance = distance,
				distance = distance+50,
				aim = true,
				position = self.build_origin+(step.offset or Vector())+Vector(0,0,65),
				aim_position = self.build_origin+(step.offset or Vector()),
				accuracy = 1,
				finish_callback = function(action, state, result, reason)
					if state == action.STATE_FINISHED and result then
						step.class = step.class or "prop_physics"
						local ent = ents.Create(step.class or "prop_physics")
						if step.model or step.class == "prop_physics" then
							ent:SetModel(step.model or "models/Combine_Helicopter/helicopter_bomb01.mdl")
						end
						if step.skin then
							ent:SetSkin(step.skin)
						end
						-- implement support for other properties of the entity
						ent:SetPos(self.build_origin+(step.offset or Vector()))
						self.build_ents[step.name] = ent
					end
				end,
			})] = true
		elseif step.type == "tool" then
			local entity = self.ent.build_ents[step.ent]
			if not (step.ent and entity and entity:IsValid()) then
				return self.STATE_INVALID, string.format("Invalid ent ID %q of step #%s", tostring(step.ent), k)
			end
			self.current_actions[self:RunAction("ToolEnt", {
				ent = entity,
				finish_callback = function(action, state, result, reason)
					if result then
						if step.tool == "nocollide" then
							entity:SetCollisionGroup(COLLISION_GROUP_NONE)
							entity.CollisionGroup = COLLISION_GROUP_NONE
						elseif step.tool == "keepupright" then
							constraint.Keepupright(entity, step.angle or Angle(0,0,0), step.bone or 0, step.angularlimit or 100000)
						end
					end
				end,
			})] = true
		elseif step.type == "indirect_constraint" then
			local entity1, entity2 = self.ent.build_ents[step.ent1 or ""], self.ent.build_ents[step.ent2 or ""]
			if not (step.ent1 and entity1 and entity1:IsValid()) then
				return self.STATE_INVALID, string.format("Invalid ent1 ID %q of step #%s", tostring(step.ent1), k)
			end
			if not (step.ent2 and entity2 and entity2:IsValid()) then
				return self.STATE_INVALID, string.format("Invalid ent1 ID %q of step #%s", tostring(step.ent2), k)
			end
			self.current_actions[self:RunAction("ToolEnt", {
				ent = entity2,
				finish_callback = function(action, state, result, reason)
					if result then
						if step.constraint == "weld" then
							--self.ent.build_ents[tostring(step.ent1).."_weld_"..tostring(step.ent2)] =
							constraint.Weld(entity1, entity2, step.bone1 or 0, step.bone2 or 0, 0, step.nocollide)
						elseif step.constraint == "nocollide" then
							--self.ent.build_ents[tostring(step.ent1).."_nocollide_"..tostring(step.ent2)] =
							constraint.NoCollide(entity1, entity2, step.bone1 or 0, step.bone2 or 0)
						end
					end
				end,
			})] = true
			self.current_actions[self:RunAction("ToolEnt", {
				ent = entity1
			})] = true
		end
		-- work in progress!
	end
	function ACTION:OnFinish(state)
		if state == self.STATE_INVALID then
			MsgAll("Alan: Stopping to build contraption "..self.params.contraption.name)
			for k,v in pairs(self.ent.build_ents) do
				v:Remove()
			end
		elseif state == self.STATE_FINISHED then
			MsgAll("Alan: Finished building contraption "..self.params.contraption.name)
		end
	end
end

function ENT:Weld(ent1, ent2)
	--self.ai:RunAction("TwoEntTool", {
	--	ent1 = ent1,
	--	ent2 = ent2,
	--	callback = function(e1, e2)
	--		constraint.Weld(e1, e2, 0, 0, 0, true)
	--	end
	--})
	self.ai:RunAction("ToolEnt", {
		ent = ent2,
		finish_callback = function(action, state, result, reason)
			constraint.Weld(ent1, ent2, 0, 0, 0, true)
		end,
	})
	self.ai:RunAction("ToolEnt", {
		ent = ent1,
	})
end

do local ACTION = AISYS:RegisterAction("ToolEnt", FAIRY_ACTIONS)
	function ACTION:OnStart()
		self.ent:SelectWeapon("tool")
	end
	function ACTION:OnUpdate()
		self.mover = self:RunAction("MoveTo", {--"MoveToVisibility", {
			ent = self.params.ent,
			min_distance = self.params.min_distance or 50,
			distance = self.params.distance or 150,
			aim = true,
			aim_hit = true,
			offset = self.params.offset or Vector(0, 0, 65),
			aim_offset = self.params.aim_offset or Vector(0, 0, -65)
		})
	end
	function ACTION:OnResume(from_action, state, result)
		if not ValidEntity(self.params.ent) then
			return self.STATE_INVALID, "Entity is no longer valid"
		end
		if from_action == self.mover then
			if result then
				self.ent:ToolEffect()
				--if self.params.callback then -- No longer need this. Just use finish_callback
				--	self.params.callback(self.params.ent)
				--end
				return self.STATE_FINISHED, "Entity has been tooled"
			end
			
		else
			self.sys:FinishAction(self.mover, true, "Recreating due to interuption")
			self.mover = self:RunAction("MoveTo", {--"MoveToVisibility", {
				ent = self.params.ent,
				min_distance = self.params.min_distance or 50,
				distance = self.params.distance or 150,
				aim = true,
				aim_hit = true,
				offset = self.params.offset or Vector(0, 0, 65),
				aim_offset = self.params.aim_offset or Vector(0, 0, -65)
			})
			self.ent:SelectWeapon("tool")
		end
	end
	function ACTION:OnFinish(state)
		self.ent:SelectWeapon("none")
		return true
	end
end

function ENT:Bonk(time, playsound)
	self.ai:RunAction("Bonk", {
		duration = time,
		silent = not playsound,
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
	function ACTION:OnResume(action, state, result)
		self.ent:StopMotionController()
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
		self.ent.dt.bonked = false
		self.ent:GetPhysicsObject():EnableGravity(false)
		self.ent:StartMotionController()
		self.ent:PhysWake()
	end
	function ACTION:OnUpdate()
		if CurTime() > self.end_time then
			return self.STATE_FINISHED, "My time limit is up"
		end
	end
	function ACTION:OnFinish(state)
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
		--self.last_time = nil
		self.counter = 0
		self.starting_health = self.params.ply:Health()
		self.sound = CreateSound(self.ent, "items/medcharge4.wav")
		self.sound:PlayEx(0,0)
	end
	
	function ACTION:OnResume(action, state)
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
			self.sys:FinishAction(self.mover, true, "Recreating due to interuption")
			self.mover = self:RunAction("MoveTo", {
				ent = self.params.ply, 
				distance = (self.params.distance or 15)-5,
				min_distance = self.params.min_distance or 0,
				offset = Vector(0,0,65),
			})
		end
	end
	
	function ACTION:OnFinish(state)
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
		self.offset = self.params.offset or Vector()
		self.distance = self.params.distance or 100
		self.ent:SetRandomMovement(true, self.params.random_movement_radius or 50)
	end
	
	function ACTION:OnResume(action, state, result)
		self.ent:SetRandomMovement(true, self.params.random_movement_radius or 50)
		return self.STATE_INVALID, "I'm not sure what to do"
	end
	
	function ACTION:OnUpdate()
		if not ValidEntity(self.params.ent) then return self.STATE_INVALID, "Player no longer valid" end
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
		self.min_distance = self.params.min_distance or 0
		if self.params.aim then
			self.params.accuracy = self.params.accuracy or 0.8
		end
		self.success = false
		self.ent:SetRandomMovement(self.params.random_movement)
	end
	
	function ACTION:OnResume(action, state, result)
		self.ent:SetRandomMovement(self.params.random_movement)
		return self.STATE_INVALID, "I'm not sure what to do"
	end
	
	function ACTION:OnUpdate()
		if not ValidEntity(self.ent) or not ValidEntity(self.params.ent) then
			return self.STATE_INVALID, "Entity is invalid"
		end
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
					self.min_distance or 0
				)
			)*0.8)
		local l = self.ent:GetPos():Distance(self.params.ent:GetPos()+self.offset)
		if l < self.distance and l > self.min_distance and (
			not self.params.aim
			or self.ent:GetAngles():Forward():Dot(self.ent.target_angle:Forward()) >= self.params.accuracy
		  ) and (
		 	not self.params.aim_hit
		 	or self.ent:GetWeaponTrace().Entity == self.params.ent
		  ) then
			self.success = true
			return self.STATE_FINISHED, "Arrived to target"
		end
	end
	
	function ACTION:OnFinish(state)
		self.sys:OnEvent("TargetReached", {ent = self.params.ent})
		return self.success
	end
end

do local ACTION = AISYS:RegisterAction("MoveToWorld", FAIRY_ACTIONS)
	function ACTION:OnStart()
		self.position = self.params.position or self:GetPos()+self:GetAngles():Foward()*256
		self.aim_position = self.params.aim_position or self.position
		self.distance = self.params.distance or 100
		self.min_distance = self.params.min_distance or 0
		if self.params.aim then
			self.params.accuracy = self.params.accuracy or 0.8
		end
		self.success = false
		self.ent:SetRandomMovement(self.params.random_movement)
	end
	
	function ACTION:OnResume(action, state, result)
		self.ent:SetRandomMovement(self.params.random_movement)
		return self.STATE_INVALID, "I'm not sure what to do"
	end
	
	function ACTION:OnUpdate()
		local dir = (self.position - self.ent:GetPos())
		if self.params.aim then
			self.ent.target_angle = ((self.aim_position or Vector())-self.ent:GetPos()):Angle()
		end
		self.ent.target_position = self.position
			-dir:GetNormalized()*math.min(
				self.distance,
				math.max(
					self.min_distance,
					dir:Length()
				)
			)*0.8
		local l = (self.position-self.ent:GetPos()):Length()
		--print("Very special dot product:", self.ent:GetAngles():Forward():Dot(self.ent.target_angle:Forward()), self.ent:GetAngles():Forward():Dot(self.ent.target_angle:Forward()) >= self.params.accuracy)
		if l < self.distance and l > self.min_distance and (
			not self.params.aim
			or self.ent:GetAngles():Forward():Dot(self.ent.target_angle:Forward()) >= self.params.accuracy
		  ) then
			self.success = true
			return self.STATE_FINISHED, "Arrived to target"
		end
	end
	
	function ACTION:OnFinish(state)
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
	
	function ACTION:OnResume(from_action, state, result)
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
			self.sys:FinishAction(self.mover, true, "Recreating due to interuption")
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
			self.sys:FinishAction(self.mover, true, "Recreating due to interuption")
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
	
	function ACTION:OnFinish(state)
		self.ent:SelectWeapon("none")
		self.sys:OnEvent("TargetKilled", {ply = self.params.ply})
	end
end

function ENT:Greet(ply)
	self.ai:RunAction("Greet", {
		ply = ply,
	})
end
do local ACTION = AISYS:RegisterAction("Greet", FAIRY_ACTIONS)
	function ACTION:OnResume(action, state, result)
		if action == self.mover then
			if self.ent:GetPos():Distance(self.params.ply:GetPos()) <= 120 then
				self.ent:Respond(self.params.ply, "Hey")
				return self.STATE_FINISHED, "I greeted the player"
			elseif not result then
				return self.STATE_INVALID, "I couldn't greet the player"
			end
		end
	end
	function ACTION:OnUpdate()
		self.sys:FinishAction(self.mover, true, "Recreating due to interuption")
		self.mover = self:RunAction("MoveTo", {--"MoveToVisibility", {
			ent = self.params.ply,
			distance = 100,
			min_distance = 50,
			offset = Vector(0, 0, 65),
			aim_offset = Vector(0, 0, 65),
			aim = true,
			accuracy = 0.8
		})
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
