import random, Rand from math
import Play from sound
import insert, remove from table
import TraceHull, GetSurfaceData from util
class SHOVE extends ACT
	Do: (fromstate) =>
		with @ply
			return unless \StanceIs STANCE_RISEN
			anim, snd, cycle1, cycle2, @bones = "range_melee_shove_1hand", nil, .15, .33, {'ValveBiped.Bip01_L_Hand'}
			if fromstate == STATE.PRIMED
				anim, snd = "gesture_push", "dysphoria/battle/push.wav"
				insert @bones, 'ValveBiped.Bip01_R_Hand'
			@Spasm sequence: anim
			@CYCLE cycle1, =>
				if IsFirstTimePredicted! and SERVER
					Play snd, \GetBonePosition(\LookupBone 'ValveBiped.Bip01_Spine2'), math.random(90,110) if snd
				@shovinIt = CurTime! + .0666
			@CYCLE cycle2, => @shovinIt = nil
	PalmDetector: (bone) =>
		palm = @ply\LookupBone bone
		pos = @ply\GetBonePosition palm
		tr = TraceHull
			start: pos
			endpos: pos + @ply\GetForward! * 10
			filter: @ply
			mins: Vector -6, -6, -6
			maxs: Vector 6, 6, 6
		return tr if tr.Hit or tr.HitWorld
	Think: =>
		super!
		if @shovinIt
			if CurTime! >= @shovinIt
				@shovinIt = CurTime! + 0.023
				for i, bone in ipairs @bones
					@ply\LagCompensation true
					tr = @PalmDetector bone
					@ply\LagCompensation false
					if tr
						remove @bones, i
						with @ply
							victim = tr.Entity
							isliving = victim\IsPlayer! or victim\IsNextBot! or victim\IsNPC!
							phys = victim\GetPhysicsObject!
							physbone = victim\GetPhysicsObjectNum tr.PhysicsBone
							aimvector = \GetAimVector!
							aimvector.z = 0
							force = aimvector*(victim\IsPlayer! and 512 or 3600)
							dir = (tr.HitPos - tr.StartPos)\GetNormalized!
							dir = (victim\GetPos! - @ply\GetPos!)\GetNormalized! if dir\Length! == 0
							dam	= random 2,3
							force = dir * (dam*23)
							if phys\IsValid!
								DropEntityIfHeld victim if SERVER
								surfprop = GetSurfaceData tr.SurfaceProps
								unless surfprop
									surfprop = GetSurfaceData 0
								snd = surfprop.impactHardSound
								if IsFirstTimePredicted!
									Play snd, tr.HitPos, 65, random(90,110)
								dmg = DamageInfo!
								with dmg
									\SetDamage dam
									\SetDamageForce force
									\SetDamageType DMG_CLUB
									\SetDamagePosition tr.HitPos + dir
									\SetInflictor @ply
									\SetAttacker @ply
								if SERVER
									victim\TakeDamageInfo dmg
									if victim\IsPlayer!
										if victim\Alive!
											if (random(100) <= 10 or victim\Health! <= 40)
												victim\FallOver dmg
											elseif victim\DoingSomething! and victim.Doing.__class.__parent == ACT.STAND
												victim\FallOver dmg
										--elseif IsValid victim\GetRagdollEntity!
											--victim\GetRagdollEntity!\SetKnockback victim\GetVelocity!, dmg\GetDamageForce!
									if victim\IsPlayer! and IsValid victim\GetRagdollEntity!
										victim = victim\GetRagdollEntity!
									if victim\IsRagdoll!
										force *= 4
										physbone\ApplyForceCenter(force, tr.HitPos)
									elseif IsValid(victim) and IsValid(phys)
										phys\ApplyForceOffset(force, tr.HitPos)
									victim\SetVelocity force

class KICK extends ACT
	Do: (fromstate) =>
		with @ply
			return unless \StanceIs STANCE_RISEN
			anim, snd, speed, cycle1, cycle2 = 'kick_pistol', 'dysphoria/battle/foot_fire.wav', 1.23, .32, .42
			if @ply\EyeAngles!.p >= 45
				anim, speed, cycle1, cycle2 = 'curbstomp', 1, .15, .66
				@stompinIt = true
			@Spasm sequence: anim, speed: speed
			@CYCLE cycle1, =>
				if IsFirstTimePredicted! and SERVER
					Play snd, \GetBonePosition(\LookupBone 'ValveBiped.Bip01_R_Foot'), math.random(90,110)
				@kickinIt = CurTime! + .0666
			@CYCLE cycle2, => @kickinIt = nil
	FootDetector: (mul=1) =>
		mul = mul or 1
        foot = @ply\LookupBone 'ValveBiped.Bip01_R_Foot'
        pos = @ply\GetBonePosition foot
        tr = TraceHull
            start: pos
        	endpos: pos + @ply\GetForward! * (10 * mul)
            filter: @ply
            mins: Vector -6, -6, -6
            maxs: Vector 6, 6, 6
		return tr if tr.Hit or tr.HitWorld
	Think: =>
		super!
		if @kickinIt and not @kickedIt
			if CurTime! >= @kickinIt
				@kickinIt = CurTime! + 0.023
				@ply\LagCompensation true
				tr = @FootDetector(@stompinIt and 1.23 or 1)
				@ply\LagCompensation false
				if tr
					with @ply
						victim = tr.Entity
						isliving = victim\IsPlayer! or victim\IsNextBot! or victim\IsNPC!
						phys = victim\GetPhysicsObject!
						physbone = victim\GetPhysicsObjectNum tr.PhysicsBone
						aimvector = \GetAimVector!
						aimvector.z = 0
						force = aimvector*(victim\IsPlayer! and 768 or 5400)
						dir = (tr.HitPos - tr.StartPos)\GetNormalized!
                        dir = (victim\GetPos! - @ply\GetPos!)\GetNormalized! if dir\Length! == 0
						dam	= random 10,25
						force = dir * (dam*23)
						if @stompinIt
							force.x = 0
							force.y = 0
							force.z = 0
						if phys\IsValid!
							DropEntityIfHeld victim if SERVER
							surfprop = GetSurfaceData tr.SurfaceProps
							unless surfprop
								surfprop = GetSurfaceData 0
							snd = surfprop.impactHardSound
							if IsFirstTimePredicted!
								Play snd, tr.HitPos, 65, random(90,110)
							dmg = DamageInfo!
							with dmg
								\SetDamage dam
								\SetDamageForce force
								\SetDamageType DMG_CLUB
								\SetDamagePosition tr.HitPos + dir
								\SetInflictor @ply
								\SetAttacker @ply
							if SERVER
								SuppressHostEvents NULL
								victim\TakeDamageInfo dmg
								SuppressHostEvents @ply
								if victim\IsPlayer!
									if victim\Alive!
										if (random(100) <= 35 and victim\Health! <= 50)
											victim\FallOver dmg
										elseif victim\DoingSomething! and victim.Doing.__class.__parent == ACT.STAND
											victim\FallOver dmg
									--elseif IsValid victim\GetRagdollEntity!
										--victim\GetRagdollEntity!\SetKnockback victim\GetVelocity!, dmg\GetDamageForce!
								if victim\IsPlayer! and IsValid victim\GetRagdollEntity!
									victim = victim\GetRagdollEntity!
								if victim\IsRagdoll!
									force *= 4
									physbone\ApplyForceCenter(force, tr.HitPos)
                                elseif IsValid(victim) and IsValid(phys)
									phys\ApplyForceOffset(force, tr.HitPos)
								victim\SetVelocity force
							@kickedIt = true

class PUNCH extends ACT
	Immobilizes: false
	Do: (fromstate) =>
		with @ply
			return unless \StanceIs STANCE_RISEN
			anim = table.Random {'gesture_punch_l', 'gesture_punch_r'}
			snd, cycle1, cycle2 = 'WeaponFrag.Throw', .13, .32
			@fist = if anim == 'gesture_punch_l' then -1 else 1
			@Spasm sequence: anim, SS: true
			@CYCLE cycle1, =>
				if IsFirstTimePredicted! and SERVER
					bone = if @fist == -1 then 'ValveBiped.Bip01_L_Hand' else 'ValveBiped.Bip01_R_Hand'
					Play snd, \GetBonePosition(\LookupBone bone), math.random(90,110)
				@punchinIt = CurTime! + .0666
			@CYCLE cycle2, => @punchinIt = nil
	FistDetector: =>
		bone = if @fist == -1 then 'ValveBiped.Bip01_L_Hand' else 'ValveBiped.Bip01_R_Hand'
		fist = @ply\LookupBone bone
		pos = @ply\GetBonePosition fist
		tr = TraceHull
			start: pos
			endpos: pos + @ply\GetForward! * 10
			filter: @ply
			mins: Vector -6, -6, -6
			maxs: Vector 6, 6, 6
		return tr if tr.Hit or tr.HitWorld
	Think: =>
		super!
		if @punchinIt and not @punchedIt
			if CurTime! >= @punchinIt
				@punchinIt = CurTime! + 0.023
				@ply\LagCompensation true
				tr = @FistDetector!
				@ply\LagCompensation false
				if tr
					with @ply
						victim = tr.Entity
						isliving = victim\IsPlayer! or victim\IsNextBot! or victim\IsNPC!
						phys = victim\GetPhysicsObject!
						physbone = victim\GetPhysicsObjectNum tr.PhysicsBone
						aimvector = \GetAimVector!
						aimvector.z = 0
						force = aimvector*(victim\IsPlayer! and 512 or 3600)
						dir = (tr.HitPos - tr.StartPos)\GetNormalized!
						dir = (victim\GetPos! - @ply\GetPos!)\GetNormalized! if dir\Length! == 0
						dam	= random 5,15
						force = dir * (dam*23)
						if phys\IsValid!
							DropEntityIfHeld victim if SERVER
							surfprop = GetSurfaceData tr.SurfaceProps
							unless surfprop
								surfprop = GetSurfaceData 0
							snd = surfprop.impactHardSound
							if IsFirstTimePredicted!
								Play snd, tr.HitPos, 65, random(90,110)
							dmg = DamageInfo!
							with dmg
								\SetDamage dam
								\SetDamageForce force
								\SetDamageType DMG_CLUB
								\SetDamagePosition tr.HitPos + dir
								\SetInflictor @ply
								\SetAttacker @ply
							if SERVER
								victim\TakeDamageInfo dmg
								if victim\IsPlayer!
									if victim\Alive!
										if (random(100) <= 15 and victim\Health! < 50)
											victim\FallOver dmg
										elseif victim\DoingSomething! and victim.Doing.__class.__parent == ACT.STAND
											victim\FallOver dmg
									--elseif IsValid victim\GetRagdollEntity!
										--victim\GetRagdollEntity!\SetKnockback victim\GetVelocity!, dmg\GetDamageForce!
								if victim\IsPlayer! and IsValid victim\GetRagdollEntity!
									victim = victim\GetRagdollEntity!
								if victim\IsRagdoll!
									force *= 4
									physbone\ApplyForceCenter(force, tr.HitPos)
								elseif IsValid(victim) and IsValid(phys)
									phys\ApplyForceOffset(force, tr.HitPos)
								victim\SetVelocity force
							@punchedIt = true