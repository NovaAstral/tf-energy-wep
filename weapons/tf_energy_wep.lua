SWEP.Author = "Nova Astral"
SWEP.PrintName = "Energy Gun"
SWEP.Purpose = "shoot the gun"
SWEP.Instructions = "LMB - Fire Energy Ball \nRMB - Fire Big Energy Ball"
SWEP.DrawCrosshair = true
SWEP.SlotPos = 10
SWEP.Slot = 3
SWEP.Spawnable = true
SWEP.Weight = 1
SWEP.HoldType = "normal"
SWEP.Primary.Ammo = "none" --This stops it from giving pistol ammo when you get the swep
SWEP.Primary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = true
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.ViewModel = "models/weapons/v_toolgun.mdl"

SWEP.Category = "Transformers Tools"

function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Holster() return true end
function SWEP:ShouldDropOnDie() return false end

function SWEP:Initialize()
    if(self.SetHoldType) then
		self:SetHoldType("pistol")
	end

	self:DrawShadow(false)

    self.ReloadDelay = CurTime()+1
end

if SERVER then
	function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime()+1)
        self:SetNextSecondaryFire(CurTime()+1)
        self.ReloadDelay = CurTime()+1

		local ply = self:GetOwner()
	end

	function SWEP:SecondaryAttack()
        self:SetNextSecondaryFire(CurTime()+1)
        self:SetNextPrimaryFire(CurTime()+1)
        self.ReloadDelay = CurTime()+1
        
		local ply = self:GetOwner()
	end

    function SWEP:Reload()
        if(self.ReloadDelay >= CurTime()) then
            return
        else
            self.ReloadDelay = CurTime()+1
        end
	end
end

timer.Simple(0.1, function() weapons.Register(SWEP,"tf_energy_wep", true) end) --Putting this in a timer stops bugs from happening if the weapon is given while the game is paused