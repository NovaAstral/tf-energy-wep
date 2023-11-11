ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.DoNotDuplicate = true

if SERVER then
    AddCSLuaFile()

    function ENT:Initialize()
        self.Entity:PhysicsInitSphere(10,"metal")
        self.Entity:SetCollisionBounds(Vector(1,1,1) * -5,Vector(1,1,1) * 5)
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self:DrawShadow(false)

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

        self:SetNotSolid(true)

        timer.Simple(0.05,function()
            self:SetNotSolid(false)
        end)

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

	/*
    function ENT:CAPOnShieldTouch(shield) --Make it hit Carter's Addon Pack shields
        self:Blast("AR2Impact",self:GetPos(),shield,Vector(1,1,1),false,self.Damage,self.Radius)
        self:Destroy()
    end
	*/

    function ENT:Think(ply)
        local phys = self:GetPhysicsObject()

        if IsValid(phys) then
            phys:Wake()
        end
    end

    function ENT:Explode()
        --self:EmitSound("")
        self:Blast("AR2Impact",self:GetPos(),self,Vector(1,1,1),self.Damage,self.Radius)
        if(self.BulletType == "toxic") then
            local ents = ents.FindInSphere(self:GetPos(),self.Radius)
            local shotowner = self:GetOwner()
            for k,ent in ipairs(ents) do
                if(ent:IsPlayer()) then
                    local dist = self:GetPos():Distance(ent:GetPos())
                    local toxtime = math.Remap(dist,1,self.Radius,10,1)

                    timer.Create("tf_wep_toxin_corrosion_effect"..ent:EntIndex(),1,toxtime,function()
                        if(not ent:Alive()) then
                            timer.Remove("tf_wep_toxin_corrosion_effect"..ent:EntIndex())
                        end

                        ent:TakeDamage(10,shotowner,shotowner)
                    end)
                end
            end

        end

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

        util.BlastDamage(self.Entity,self.Entity:GetOwner(),pos,rad,dmg)
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

if CLIENT then
	local function MaterialFromVMT(name, VMT)
		if (type(VMT) ~= "string" or type(name) ~= "string") then return Material(" ") end
		local t = util.KeyValuesToTable("\"material\"{" .. VMT .. "}")
	
		for shader, params in pairs(t) do
			return CreateMaterial(name, shader, params)
		end
	end

    ENT.Glow = MaterialFromVMT("EnBallGlow", [["UnLitGeneric"
	{
		"$basetexture"		"sprites/light_glow01"
		"$nocull" 1
		"$additive" 1
		"$vertexalpha" 1
		"$vertexcolor" 1
	}]])
    ENT.Shaft = Material("effects/ar2ground2")
    ENT.LightSettings = "cl_staff_dynlights_flight"
    ENT.RenderGroup = RENDERGROUP_BOTH

    function ENT:Initialize()
        self.Created = CurTime()
        self.DrawShaft = true

        --self.Sound = Sound("tf_energy_fire.wav") -- pass sound

        local size = self.Entity:GetNetworkedInt("Size", 0)

        self.Sizes = {20 + size * 3, 20 + size * 3, 180 + size * 10}
    end

    function ENT:Draw()
        if (not self.StartPos) then
            self.StartPos = self.Entity:GetPos()
        end

        local start = self.Entity:GetPos()
        local color = self.Entity:GetColor()

        if (self.DrawShaft) then
            local velo = self.Entity:GetVelocity()
            local dir = -1 * velo:GetNormalized()

            if (velo:Length() < 400) then
                if (self.StartPos) then
                    dir = (self.StartPos - self.Entity:GetPos()):GetNormalized()
                end
            end

            local length = math.Clamp((self.Entity:GetPos() - self.StartPos):Length(), 0, self.Sizes[3])
            render.SetMaterial(self.Shaft)
            render.DrawBeam(self.Entity:GetPos(), self.Entity:GetPos() + dir * length, self.Sizes[1], 1, 0, color)
        end

        render.SetMaterial(self.Glow)

        for i = 1, 2 do
            render.DrawSprite(start, self.Sizes[2], self.Sizes[2], color)
        end
    end

    function ENT:Think()
        local size = self.Entity:GetNWInt("Size", 0)

        self.Sizes = {20 + size * 3, 20 + size * 3, 180 + size * 10}

        local color = self.Entity:GetColor()
        local r, g, b = color.r, color.g, color.b
        local dlight = DynamicLight(self:EntIndex())

        if (dlight) then
            dlight.Pos = self.Entity:GetPos()
            dlight.r = r
            dlight.g = g
            dlight.b = b
            dlight.Brightness = 1
            dlight.Decay = 300
            dlight.Size = 300
            dlight.DieTime = CurTime() + 0.5
        end

        local time = CurTime()
        /* --pass sound
        if ((time - self.Created >= 0.1 or self.InstantEffect) and time - (self.Last or 0) > 0.3) then
            local p = LocalPlayer()
            local pos = self.Entity:GetPos()
            local norm = self.Entity:GetVelocity():GetNormal()
            local dist = p:GetPos() - pos
            local len = dist:Length()
            local dot_prod = dist:Dot(norm) / len
            
            if (math.abs(dot_prod) < 0.5 and dot_prod ~= 0 and len < 500) then
                local intensity = math.sqrt(1 - dot_prod ^ 2) * len
                self.Entity:EmitSound(self.Sound, 100 * (1 - intensity / 2500), math.random(80, 120))
                self.Last = time
            end
        end
        */
        self.Entity:NextThink(time)

        return true
    end
end