ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Alan"
ENT.Author = "CapsAdmin"
ENT.Contact = "sboyto@gmail.com"

ENT.Spawnable	= true
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:DTVar("Float", 0, "size")
	self:DTVar("Vector", 0, "color")
	self:DTVar("Bool", 0, "bonked")
	self:DTVar("Bool", 1, "isthinking")
end