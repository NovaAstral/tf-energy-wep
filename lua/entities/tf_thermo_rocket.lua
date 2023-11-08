ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.DoNotDuplicate = true

if SERVER then
    AddCSLuaFile()

    function ENT:Initialize()
        self.Entity:SetModel("models/megarexfoc/thermo_rocket_spinning.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self:DrawShadow(false)

        local trail = util.SpriteTrail( self, 1, Color( 255, 255, 255 ), false, 5, .5, 1, 25 / ( 500 + 1 ) * 1, "trails/smoke.vmt" )
        local trail = util.SpriteTrail( self, 2, Color( 255, 255, 255 ), false, 5, .5, 1, 25 / ( 500 + 1 ) * 1, "trails/smoke.vmt" )
        local trail = util.SpriteTrail( self, 3, Color( 255, 255, 255 ), false, 5, .5, 1, 25 / ( 500 + 1 ) * 1, "trails/smoke.vmt" )

        self.Radius = 50 * self.Size
        self.Damage = 70 * self.Size
        local color = self.Entity:GetColor()
        local r,g,b = color.r, color.g, color.b

        self.Entity:SetRenderMode(RENDERMODE_TRANSALPHA)
        self:PhysWake()
        self.Phys = self.Entity:GetPhysicsObject()
        local vel = self.Direction * self.Speed + VectorRand() * self.Random

        if(self.Phys and self.Phys:IsValid()) then
            self.Phys:SetMass(self.Size * 10)
            self.Phys:EnableGravity(false)
            self.Phys:SetVelocity(vel) -- end
        end

        self.Entity:SetLocalVelocity(vel)
        self.Created = CurTime()
    end

    function ENT:UpdateTransmitState()
        return TRANSMIT_ALWAYS
    end

    function ENT:PhysicsUpdate(phys)
        local vel = phys:GetVelocity()

        if(math.abs(vel.x) < 500 and math.abs(vel.y) < 500 and math.abs(vel.z) < 500) then
            self:Destroy()
        end
    end

    function ENT:Think(ply)
        local phys = self:GetPhysicsObject()

        if IsValid(phys) then
            phys:Wake()
        end
    end

    function ENT:Explode()
        self:Blast("Explosion",self:GetPos(),self,Vector(1,1,1),self.Damage,self.Radius)

        self:Destroy()
    end

    function ENT:PhysicsCollide(data,physobj)
        local ent = data.HitEntity

        if(ent) then
            local pos = data.HitPos
            local owner = self.Entity:GetOwner()

            if(owner == nil) then
                owner = self.Entity
            end

			if(owner == ent) then return end

            local hitnormal = data.HitNormal

            if(ent:IsWorld())then
                hitnormal = -1 * hitnormal
            end

            local dir = self.Direction * 10

            local trace = util.TraceLine({
                start = pos - dir,
                endpos = pos + dir,
                filter = {self.Entity, owner}
            })

            if trace then
                if trace.HitSky then
                    self.Entity:Destroy()
                    return
                end
            end
            
            self:Explode()
        end
    end

    function ENT:Blast(effect,pos,ent,norm,dmg,rad)
        local fx = EffectData()
        fx:SetOrigin(pos)
        fx:SetNormal(norm)
        fx:SetEntity(ent)
        fx:SetScale(1)

        fx:SetMagnitude(self.Size)
        local c = self.Entity:GetColor()
        fx:SetAngles(Angle(c.r, c.g, c.b))
        util.Effect(effect, fx, true, true)

        util.BlastDamage(self.Entity,self.Entity:GetOwner(),pos,250,dmg)
        util.ScreenShake(pos, 2, 2.5, 1, 700)
    end

    function ENT:PrepareBullet(dir,rand,spd,size,btype)
        self.Direction = dir
        self.Random = rand
        self.Speed = spd
        self.Size = size
        self.Entity:SetNWInt("Size",size)
        self.BulletType = btype
    end

    function ENT:Destroy()
        if(IsValid(self.Entity))then
            self.Entity:Remove()
        end
    end
end