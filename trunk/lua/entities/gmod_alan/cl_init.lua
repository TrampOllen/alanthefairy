include("shared.lua")
include("cl_zelda.lua")

local model = Model("models/python1320/wing.mdl")
local lightsprite = Material("Sprites/light_glow02_add")
local yellowflare = "particle/fire"
local trail = Material("trails/laser")

local sunbeams = CreateClientConVar("alan_sunbeams", "1", true, false)
local trails = CreateClientConVar("alan_trails", "1", true, false)
language.Add("gmod_alan", "Fairy")

local function Wrap( string, width )
	local tbl = {}
	for key, value in pairs(markup.Parse(string, width).blocks) do
		table.insert(tbl, value.text)
	end
	return tbl
end

function ENT:Initialize()
	
	--self:DrawTranslucent()
	
	self:SetupThirdperson()
	
	self.speed = 6.3
	self.flaplength = 50
	self.wingsize = 0.3
	
	self.dotindex = 0
	
	self.sunbeams = {}
	
	self.flap = CreateSound(self, "alan/flap.wav")
	self.float = CreateSound(self, "alan/float.wav")
	
	self.flap:Play()
	self.float:Play()
	
	self.flap:ChangeVolume(0.3)
	
	self.emitter = ParticleEmitter(self:GetPos())
	
	self.light = DynamicLight(self:EntIndex())
	
	self.leftwing = ClientsideModel(model)
	self.rightwing = ClientsideModel(model)	
	self.bleftwing = ClientsideModel(model)
	self.brightwing = ClientsideModel(model)
	
	self.leftwing:SetMaterial("alan/wing")
	self.rightwing:SetMaterial("alan/wing")
	self.bleftwing:SetMaterial("alan/wing")
	self.brightwing:SetMaterial("alan/wing")
	
	self:SetRenderBoundsWS(self:GetPos()-self:GetRight()*500, self:GetPos()+self:GetRight()*500)
	
	usermessage.Hook( "Alan:ToPlayer", function( um )
		local ply = um:ReadEntity()
		local uniqueID = um:ReadString()
		local text = string.Replace(um:ReadString(), uniqueID, ply:Name())
		chat.AddText(self.color, "Alan", Color( 255, 255, 255, 255 ), " to ", team.GetColor(ply:Team()), ply:GetName(), Color( 255, 255, 255, 255 ), ": " .. text)
		self.current_text = Wrap(text or "", ScrW()/2)
		self.current_player = ply
	end)
	
	usermessage.Hook( "Alan:Respond", function( um )
		local text = um:ReadString()
		chat.AddText(self.color, "Alan", Color( 255, 255, 255 ), ": " .. text)
	end)
	
	hook.Add("HUDPaint", "Alan Thinking", function()
		if not self:IsValid() then return end
		if not self.dt.isthinking then return end
		
		local dots = {".", "..", "..."}
	
		self.dotindex = self.dotindex + 0.01
		
		if self.dotindex >= 3 then self.dotindex = 0 end
		
		local position = (self:GetPos()+Vector(0,0,self.dt.size*2)):ToScreen()
		local x, y = position.x, position.y
		local alpha = 255

		if self:GetPos():Distance(LocalPlayer():GetPos()) > 400 then
			alpha = 0
		end
		
		local color_bg = Color(255, 255, 255, alpha)
		surface.SetDrawColor(color_bg)
		surface.DrawPoly{{x=x+3,y=y+30,u=0,v=0},
						{x=x+15,y=y+30,u=1,v=0},
						{x=x+0,y=y+40,u=0,v=1},
						{x=x+0,y=y+40,u=1,v=1}}
		
		draw.WordBox( 8, x, y, dots[math.Clamp(math.Round(self.dotindex), 1, #dots)], "ScoreboardText", color_bg, color_black )
	end)
end

function ENT:SetAlanText(text)
	self.current_text = Wrap(text or "", ScrW()/2)
end

function ENT:RenderTrail(material, color, length, startsize)
	if material:IsError() or not trails:GetBool() then return end
	self.traildata = self.traildata or {}
	self.traildata.points = self.traildata.points or {}

	table.insert(self.traildata.points,self:GetPos())
	if #self.traildata.points > length then table.remove(self.traildata.points, #self.traildata.points - length) end

	cam.Start3D(EyePos(), EyeAngles())
		render.SetMaterial(material)
		render.StartBeam(#self.traildata.points)
			for k,v in pairs(self.traildata.points) do
				local width = k / (length / startsize)
				render.AddBeam(v,width,width,color)
			end
		render.EndBeam()
	cam.End3D()
end

function ENT:VectorRandSphere()
	return Angle(math.Rand(-180,180),math.Rand(-180,180),math.Rand(-180,180)):Up()
end

local once = true

function ENT:Think()

	if once then
		self:SetupThirdperson()
		once = false
	end

	self.color = Color(self:GetColor())
	
	if self:WaterLevel() > 0 then
		--ParticleEffectAttach("water_mist_256",PATTACH_ABSORIGIN_FOLLOW,self,0)
	end

	if self.dt.bonked then
		self.speed = 0
		self.flap:FadeOut()
	else
		self.speed = 6.3
		self.flap:Play()
		self.flap:ChangeVolume(0.3)
	end
	
	self.sunbeams.amount = self.dt.size / 20
	self.sunbeams.distance = 1000
	self.sunbeams.size = 0.05
	local length = self:GetVelocity():Length()

	self.float:ChangePitch(length/50+100)
	self.float:ChangeVolume(length/100)
	
	self.flap:ChangePitch(length/50+100)
	
	local particle = self.emitter:Add(yellowflare, self:GetPos())
	if particle then
		particle:SetVelocity(self:VectorRandSphere() * self.dt.size * 10)
		particle:SetColor(self.color.r,self.color.g,self.color.b)
		particle:SetDieTime(math.Rand(1, 2))
		particle:SetAirResistance(10)
		particle:SetGravity(self.dt.bonked and Vector(0,0,-50) or Vector(0))
		particle:SetStartAlpha(0)
		particle:SetEndAlpha(255)
		particle:SetStartSize(self.dt.size*2)
		particle:SetEndSize(0)
		particle:SetCollide(true)
		particle:SetRoll(math.random())
	end
	if self.light then
		self.light.Pos = self:GetPos()
		self.light.r = self.color.r
		self.light.g = self.color.g
		self.light.b = self.color.b
		self.light.Brightness = self.dt.size * 2
		self.light.Size = self.dt.size * 256
		self.light.Decay = self.dt.size * 32 * 5
		self.light.DieTime = CurTime() + 1
	end
end

function ENT:DrawEntityOutline()
	--Override the outline drawing
end

local function EasySunbeams()
	for key, alan in pairs(ents.FindByClass("gmod_alan")) do
		alan:RenderTrail(trail, alan.color, 100, alan.dt.size * 30)
		cam.Start3D(EyePos(), EyeAngles())
			render.SetMaterial(lightsprite)
			render.DrawSprite(alan:GetPos(), alan.dt.size * 64, alan.dt.size * 64, alan.color)
			render.DrawSprite(alan:GetPos(), alan.dt.size * 32, alan.dt.size * 32, alan.color)
			render.DrawSprite(alan:GetPos(), alan.dt.size * 16, alan.dt.size * 16, alan.color)
		cam.End3D()
		if not sunbeams:GetBool() then return end
		if alan and alan.sunbeams and alan.sunbeams.amount ~= 0 and EyePos():Distance(alan:GetPos()) < alan.sunbeams.distance then
			local dotProduct = math.Clamp(EyeVector():DotProduct((alan:GetPos()-EyePos()):Normalize())-0.5, 0, 1) * 2
			if dotProduct > 0 then
				local screenPos = alan:GetPos():ToScreen()
				DrawSunbeams(0, (alan.sunbeams.amount*dotProduct)*math.Clamp((alan:GetPos()-EyePos()):Length() / -alan.sunbeams.distance + 1, 0, 1), alan.sunbeams.size, screenPos.x / ScrW(), screenPos.y / ScrH())
			end
		end
	end
end

hook.Add("RenderScreenspaceEffects", "Alan sunbeams", EasySunbeams)

function ENT:Draw()
	
	self.leftwing:SetModelScale(Vector(1,0.5,1)*self.dt.size*self.wingsize)
	self.rightwing:SetModelScale(Vector(1,0.5,1)*self.dt.size*self.wingsize)
	
	self.bleftwing:SetModelScale(Vector()*(self.dt.size/3*self.wingsize))
	self.brightwing:SetModelScale(Vector()*(self.dt.size/3*self.wingsize))
	
	self.leftwing:SetColor(self.color.r,self.color.g,self.color.b,255)
	self.rightwing:SetColor(self.color.r,self.color.g,self.color.b,255)
	self.bleftwing:SetColor(self.color.r,self.color.g,self.color.b,255)
	self.brightwing:SetColor(self.color.r,self.color.g,self.color.b,255)
		
	local offsetangle = Angle(0,0,-20)
	
	local leftposition, leftangles = LocalToWorld(Vector(0), Angle(0,TimedSin(self.speed,-self.flaplength,0,0), 0) + Angle(0,290,0) + offsetangle, self:GetPos(), self:GetAngles())
	local rightposition, rightangles = LocalToWorld(Vector(0), Angle(0,TimedCos(self.speed,0,self.flaplength,0), 0) + Angle(0,290,0) + offsetangle, self:GetPos(), self:GetAngles())
	
	self.leftwing:SetPos(leftposition)
	self.rightwing:SetPos(rightposition)
	
	self.leftwing:SetAngles(leftangles)
	self.rightwing:SetAngles(rightangles)

	local bleftposition, bleftangles = LocalToWorld(Vector(0), Angle(TimedSin(self.speed,-self.flaplength,0,0),0, 0) + Angle(20,260,60) + offsetangle, self:GetPos(), self:GetAngles())
	local brightposition, brightangles = LocalToWorld(Vector(0), Angle(TimedCos(self.speed,0,self.flaplength,0),0, 0) + Angle(20,260,60) + offsetangle, self:GetPos(), self:GetAngles())
		
	self.bleftwing:SetPos(bleftposition)
	self.brightwing:SetPos(brightposition)
	
	self.bleftwing:SetAngles(bleftangles)
	self.brightwing:SetAngles(brightangles)
	
	self.leftwing:DrawModel()
	self.rightwing:DrawModel()
	self.bleftwing:DrawModel()
	self.brightwing:DrawModel()
end

function ENT:OnRemove()
	self.leftwing:Remove()
	self.rightwing:Remove()
	self.bleftwing:Remove()
	self.brightwing:Remove()
	self.flap:Stop()
	self.float:Stop()
end