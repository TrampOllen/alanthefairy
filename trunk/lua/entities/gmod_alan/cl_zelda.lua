local enable = CreateClientConVar("alan_zelda_enable", 0)

function ENT:SetupThirdperson()
	
	local smooth_origin = EyePos() or Vector(0)
	local smooth_direction = EyeVector() or Vector(0)
	local smooth_fov = 0

	hook.Add("CalcView", "Alan Zelda Thirdperson", function(ply,origin,angles,fov)
		if not enable:GetBool() or not ValidEntity(self) then
			smooth_origin = EyePos()
			smooth_direction = EyeVector()
		return end
		smooth_origin = smooth_origin + (((self:GetPos() + origin) / 2 + ply:EyeAngles():Forward()*-100 - smooth_origin) / 100)
		smooth_fov = smooth_fov + ((50 - fov) / 100)
		smooth_direction = smooth_direction + (((self:GetPos()-smooth_origin) - smooth_direction) / 50)
		return GAMEMODE:CalcView(ply,smooth_origin,smooth_direction:Angle(),50)
	end)

	hook.Add("ShouldDrawLocalPlayer", "Alan Zelda Draw Player", function(ply)
		if enable:GetBool() or not ValidEntity(self) then
			return true
		end
	end)
	
	local hide = {
		"CHudHealth",
		"CHudBattery",
		"CHudAmmo",
		"CHudSecondaryAmmo",
		"CHudCrosshair",		
	}
	
	hook.Add("HUDShouldDraw", "Hide HUD Alan", function(hud)
		if enable:GetBool() and ValidEntity(self) and table.HasValue(hide, hud) then return false end
	end)
	
	local smooth_bar = 0	
	
	hook.Add("HUDPaint", "Draw Black Bars", function()
		if not enable:GetBool() or not ValidEntity(self) then 
			smooth_bar = 0
		return end
		smooth_bar = smooth_bar + ((150 - smooth_bar) / 50)
		surface.SetDrawColor( 0, 0, 0, 255)
		surface.DrawRect(0 , ScrH()-smooth_bar, ScrW(), smooth_bar )
		surface.DrawRect(0 , 0, ScrW(), smooth_bar )
				
		if ValidEntity(self.current_player) and self.current_player == LocalPlayer() then
			surface.SetTextColor( 200, 200, 200, 255 )
			surface.SetFont("CloseCaption_Bold")
			local y = 0
			for key, value in pairs(self.current_text) do
				local width, height = surface.GetTextSize(value)
				y = y + height
				surface.SetTextPos( ScrW()/2-(width/2), ScrH()-smooth_bar+65+y-height ) 
				surface.DrawText( value )
			end
		end
	end)

end