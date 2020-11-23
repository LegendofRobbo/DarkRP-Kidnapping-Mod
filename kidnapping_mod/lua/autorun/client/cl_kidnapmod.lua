local duration = CurTime()
local kidnapper = game.GetWorld()


surface.CreateFont( "KidnapFont", {
	font = "Tahoma",
	size = 38,
	weight = 450,
} )

surface.CreateFont( "KidnapFontSmall", {
	font = "Tahoma",
	size = 28,
	weight = 450,
} )


net.Receive("Kidnapped", function() 
local v1 = net.ReadUInt( 8 ) or 0
local v2 = net.ReadEntity()

duration = CurTime() + v1
kidnapper = v2
end)


local function DrawBlackScreen()
if duration > CurTime() then
surface.SetDrawColor(Color(0,0,0))
surface.DrawRect(0, 0, ScrW(), ScrH() )
if kidnapper:IsValid() and kidnapper:IsPlayer() then
	draw.SimpleText( "You have been knocked out by: "..kidnapper:Nick(), "KidnapFont", ScrW() / 2, ScrH() / 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
else
	draw.SimpleText( "You have been knocked out by unknown forces", "KidnapFont", ScrW() / 2, ScrH() / 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end
draw.SimpleText( "Time until you wake up: "..math.Round( (duration - CurTime()) + 0.5 ), "KidnapFontSmall", ScrW() / 2, ScrH() / 2 + 40, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )


end


end
hook.Add("HUDPaint", "kidnap_drawblackscreen", DrawBlackScreen)


hook.Add("HUDPaint", "DrawPlayerGearBoxes", function()
	local tr = LocalPlayer():GetEyeTrace()
	if !tr.Entity:IsValid() or tr.Entity:GetClass() != "kidnapped_inventory" or LocalPlayer():GetPos():Distance( tr.Entity:GetPos() ) > 200 then return end
	local ent = tr.Entity
	local owner = ent:GetNWEntity( "gear_owner", game.GetWorld() )
	if !owner:IsValid() then return end
 
	local p = ent:LocalToWorld(ent:OBBCenter()):ToScreen()
	draw.DrawText(owner:Nick().."'s gear","Trebuchet24",p.x,p.y,Color(255,255,255, 150),1)

end)