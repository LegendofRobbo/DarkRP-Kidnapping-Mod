SWEP.Category          = "DarkRP"
SWEP.Instructions   = "Sneak up behind people and use left click to knock them out.  Right click picks their body up and allows you to cart them to your rape dungeon."
SWEP.ViewModelFlip		= false
SWEP.ViewModel 			= "models/weapons/v_stunbaton.mdl"
SWEP.WorldModel 		= "models/weapons/w_stunbaton.mdl"
SWEP.ViewModelFOV 		= 55
SWEP.BobScale 			= 2
SWEP.DrawCrosshair 			= false
SWEP.HoldType 			= "melee2"
SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.Primary.Recoil		= 5
SWEP.Primary.Damage		= 0
SWEP.Primary.NumShots		= 0
SWEP.Primary.Cone			= 0.075
SWEP.Primary.Delay 		= 1.5

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= ""

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"

SWEP.ShellEffect			= "none"
SWEP.ShellDelay			= 0

SWEP.Pistol				= true
SWEP.Rifle				= false
SWEP.Shotgun			= false
SWEP.Sniper				= false

SWEP.RunArmOffset 		= Vector (0, 0, 0)
SWEP.RunArmAngle	 		= Vector (0, 0, 0)

SWEP.Sequence			= 0

SWEP.HitDistance = 55


function SWEP:Deploy()

	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	self.Weapon:SetNextPrimaryFire(CurTime() + 1)

	self.Weapon:SetHoldType("melee2")

	return true
end


function SWEP:HitTheirBack( ply )

	local angle = self.Owner:GetAngles().y - ply:GetAngles().y

	if angle < -180 then angle = 360 + angle end
	if angle <= 50 and angle >= -50 then return true end

	return false
end



function SWEP:PrimaryAttack()

	self.Weapon:SendWeaponAnim(ACT_VM_MISSCENTER)

	timer.Simple( 0.2, function()
	if ( !IsValid( self ) || !IsValid( self.Owner ) || !self.Owner:GetActiveWeapon() || self.Owner:GetActiveWeapon() != self || CLIENT ) then return end
	self:DealDamage( anim )
	self.Owner:EmitSound( "weapons/slam/throw.wav" )
	end )

	timer.Simple( 0.02, function()
	if ( !IsValid( self ) || !IsValid( self.Owner ) || !self.Owner:GetActiveWeapon() || self.Owner:GetActiveWeapon() != self ) then return end
	self.Owner:ViewPunch( Angle(-0.5, -0.5, 0.5) )
	end )

	timer.Simple( 0.2, function()
	if ( !IsValid( self ) || !IsValid( self.Owner ) || !self.Owner:GetActiveWeapon() || self.Owner:GetActiveWeapon() != self ) then return end
	self.Owner:ViewPunch( Angle( math.Rand(1,2), 1, -1 ) )
	end )

	if self.Weapon:GetNetworkedBool("Holsted") then return end

	self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self.Weapon:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
	self.Owner:SetAnimation(PLAYER_ATTACK1)


	if ((game.SinglePlayer() and SERVER) or CLIENT) then
		self.Weapon:SetNetworkedFloat("LastShootTime", CurTime())
	end
end


function SWEP:DoPickup(ent)
	if ent:IsPlayerHolding() then
		return
	end

	timer.Simple(FrameTime() * 10, function()
		if (!IsValid(ent) or ent:IsPlayerHolding()) then
			return
		end

		self.Owner:PickupObject(ent)
		self.Owner:EmitSound("physics/body/body_medium_impact_soft"..math.random(1, 3)..".wav", 75)
	end)

	self:SetNextSecondaryFire(CurTime() + 1)
end



function SWEP:SecondaryAttack()
	local trace = self.Owner:GetEyeTrace()
	local ent = trace.Entity

	if SERVER and ent:IsValid() and ent:GetClass() == "prop_ragdoll" and self.Owner:EyePos():Distance(trace.HitPos) < 100 then
		if self.Owner:KeyDown(IN_USE) then 
			kidnapper:ConfiscatePlayerGear( ent, self.Owner )
			self:EmitSound("npc/combine_soldier/gear5.wav", 50, 100)
			self:SetNextSecondaryFire( CurTime() + 0.5 )
		else
			local phys = ent:GetPhysicsObject()
			phys:Wake()
			self:DoPickup( ent )
		end

	end

end

function SWEP:DealDamage( anim )
	local tr = util.TraceLine( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
		filter = self.Owner
	} )

	if ( !IsValid( tr.Entity ) ) then 
		tr = util.TraceHull( {
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
			filter = self.Owner,
			mins = Vector( -10, -10, -8 ),
			maxs = Vector( 10, 10, 8 )
		} )
	end

	if ( tr.Hit ) then 
		self.Weapon:EmitSound("physics/plastic/plastic_barrel_impact_hard"..math.random(1,4)..".wav", 60, 115)
	end


	if ( IsValid( tr.Entity ) && ( tr.Entity:IsPlayer() and tr.Entity:Alive() ) ) then
		local dmginfo = DamageInfo()
		local ply = tr.Entity
		self.Weapon:EmitSound("physics/flesh/flesh_strider_impact_bullet2.wav", 80, 115)
		if ply.LastKidnapped and ply.LastKidnapped > CurTime() and self:HitTheirBack( ply ) then DarkRP.notify(self.Owner, 1, 4, "This player cannot be knocked out again for another "..math.Round(ply.LastKidnapped - CurTime()).." seconds") self.Weapon:SetNextPrimaryFire(CurTime() + 5) return end
		if self:HitTheirBack( ply ) and kidnapper:CanKnockout( ply ) then kidnapper:Knockout( ply, self.Owner ) self.Weapon:SetNextPrimaryFire(CurTime() + kidnapper.WeaponCooldown) end
		dmginfo:SetDamage( 5 )
		dmginfo:SetDamageForce( self.Owner:GetRight() * 425 + self.Owner:GetForward() * 94 ) -- Yes we need those specific numbers
		dmginfo:SetInflictor( self )
		local attacker = self.Owner
		if ( !IsValid( attacker ) ) then attacker = self end
		dmginfo:SetAttacker( attacker )

		tr.Entity:TakeDamageInfo( dmginfo )
	end
end
