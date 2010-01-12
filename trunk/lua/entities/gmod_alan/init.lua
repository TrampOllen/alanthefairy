AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

resource.AddFile("sound/alan/flap.wav")
resource.AddFile("sound/alan/float.wav")
resource.AddFile("sound/alan/bonk.wav")
resource.AddFile("models/python1320/wing.mdl")

include("shared.lua")
include("sv_hooks.lua")
include("sv_weapons.lua")
include("sv_build.lua")
include("sv_alan.lua")
include("sv_actions.lua")

local alan_name = CreateConVar("alan_name", "Alan", true, false)
local alan_color = CreateConVar("alan_color", "200 255 200", true, false)
local alan_size = CreateConVar("alan_size", "1", true, false)

function ENT:Initialize()
	self.dt.size = alan_size:GetFloat()
	local color = string.Explode(" ", alan_color:GetString())
	self:SetColor(color[1],color[2],color[3], 255)
	self:SetModel("models/dav0r/hoverball.mdl")
	self:PhysicsInitBox(Vector()*-self.dt.size*5, Vector()*self.dt.size*5)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:DrawShadow(false)
	self:CreateTool()
	self:StartMotionController()
	self.shadowcontrol = {}
	self.sphereposition = Vector(0)
	self.smoothsphererandom = Vector(0)
	
	self.curtime = CurTime()
	self.randomspheretime = math.Rand(1,3)
		
	alan = self
	
	self:InitializeWeapons()
	
	local physicsobject = self:GetPhysicsObject()
		
	if (physicsobject:IsValid()) then
		physicsobject:Wake()
		physicsobject:EnableGravity(false)
		physicsobject:SetMass(self.dt.size*100)
		physicsobject:SetMaterial("gmod_bouncy")
	end
	
	self.ai = AISYS:Create(self)
	self.ai:RunAction("CoreFairyBehaviour")
	self:InitializeHooks(self.ai)
end

function ENT:SpawnFunction(ply, trace)
	local alan = ents.Create("gmod_alan")
	alan:SetPos(ply:GetShootPos() + Vector(0,0,50))
	alan:Spawn()
	alan.following = ply
	ply.hasalan = true
	ply.alan = alan
	return alan
end

function ENT:PhysicsCollide(data, physicsobject)
	if data.Speed > 50 and data.DeltaTime > 0.2  then
		--self:Bonk(data.Speed / 100, true)
	end
end

function ENT:AddChatCommand(command, callback)
	self.commands = self.commands or {}
	self.commands[command] = callback
end

function ENT:OnTakeDamage(damageinfo)
	--self:Bonk(math.Clamp(damageinfo:GetDamage(),0, 5))
end

function ENT:OnRemove()
	self:CreateWeaponOnRemove()
	for key, weapon in pairs(self.weapons) do
		weapon:Remove()
	end
	self:RemoveTimers()
end

function ENT:RemoveTimers()
	timer.Remove("Alan Bonked"..self:EntIndex())
end

function ENT:RandomSphere(radius)
	return Angle(math.Rand(-180,180),math.Rand(-180,180),math.Rand(-180,180)):Forward() * math.random(radius)
end

function ENT:PhysicsSimulate( physicsobject, deltatime )
	self.smoothsphererandom = self.smoothsphererandom + ((self.sphereposition - self.smoothsphererandom)/100)
	
	physicsobject:Wake()
	self.shadowcontrol.secondstoarrive = 0.5
	self.shadowcontrol.pos = self.target_position or self:GetPos() -- self.smoothsphererandom)
	self.shadowcontrol.angle = self.target_angle or self:GetVelocity():Angle()
	self.shadowcontrol.maxangular = 100000
	self.shadowcontrol.maxangulardamp = 400
	self.shadowcontrol.maxspeed = 1000000
	self.shadowcontrol.maxspeeddamp = 10000
	self.shadowcontrol.dampfactor = 0.8
	self.shadowcontrol.teleportdistance = 0
	self.shadowcontrol.deltatime = deltatime
	physicsobject:ComputeShadowControl(self.shadowcontrol)	
end

function ENT:GetEyeTrace()
	return util.QuickTrace(self:GetPos(), self:GetAngles():Forward()*1000000, self)
end

function ENT:GetWeaponTrace()
	if not self.activeweapon then return end
	local attachment = self.activeweapon:GetAttachment(1)
	return util.QuickTrace(attachment.Pos, attachment.Ang:Forward()*1000000, {self.activeweapon, self})
end

function ENT:Think()
	if self.curtime + self.randomspheretime <= CurTime() and self.following and self.userandommovement then
		self.sphereposition = self:RandomSphere(self.following and self.following:BoundingRadius()*3)
		self.randomspheretime = math.Rand(0,1)
		self.curtime = CurTime()
	end
	
	local stringcolor = alan_color:GetString()
	
	if stringcolor ~= self.laststringcolor then
		local color = string.Explode(" ", stringcolor)
		self:SetColor(color[1],color[2],color[3], 255)
		self.laststringcolor = stringcolor
	end
	
	local size = alan_size:GetFloat()
	
	if size ~= self.lastsize then
		self.dt.size = size
		self.lastsize = size
	end
	self.ai:Update()
end

function ENT:SetRandomMovement(boolean)
	if boolean then
		self.userandommovement = true
	else
		self.userandommovement = false
		self.sphereposition = Vector(0)
	end
end

function ENT:SetPickedup(bool)
	if bool then
		self:StopMotionController()
	end
	
	if not bool and not self.dt.bonked then
		self:StartMotionController()
	end
end

function ENT:SetActiveEntity(entity)
	self.active_entity = entity
end

function ENT:GetActiveEntity(entity)
	return self.active_entity
end