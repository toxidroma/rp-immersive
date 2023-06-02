anims =
	headbutt: {
        'FLINCH_Head_Small_01'
        'FLINCH_Head_Small_02'
        'ZOMBIE_flinch_head'
        'FLINCH_Gen_Small_03'
    }

FALLEN
hook.Add 'SetupPlayerDataTables', _PKG\GetIdentifier'misadventure', (classy) ->
    with classy
        \NetworkVar 'Bool',    'Fallen'
    nil

class STAND extends ACT
    Do: => @Spasm sequence: @anim, SS: true
class FRONT extends STAND
    anim: 'wos_mma_standup_front01'
class BACK extends STAND
    anim: 'wos_mma_standup_back01'

BIND 'fallover',
    KEY_T, {
        Press: (ply) =>
            with ply
                return if ply\GetFallen!
                unless \DoingSomething!
                    if SERVER
                        \FallOver!
    }

import min, abs, ceil from math
import TraceHull from util
TUMBLE_SOFT, TUMBLE_OUCH, TUMBLE_HARD     = 150, 225, 285
bounds = 
    Hull:
        mins: Vector -13, -13, 12
        maxs: Vector 13, 13, 72
    Head:
        attach: 'eyes'
        mins: Vector -5, -4, -3.5
        maxs: Vector 5, 4, 3.5
        Ouch: (hit, ply, speeds) ->
            if hit.HitNormal.x != 0 then hit.HitPos.z = hit.HitPos.z + 12
            if speeds >= TUMBLE_OUCH
                return unless IsFirstTimePredicted!
                force = Vector!
                unless hit.HitWorld
                    force = (hit.StartPos - hit.HitPos)\GetNormal! * speeds/2
                ply\EmitSound 'Flesh.ImpactHard'
                ply\SetSpeedLerp min ply\GetSpeedTarget!, 150
                --do damage based on the speed of impact
                crashpct = speeds / TUMBLE_HARD
                if SERVER
                    with dmg = DamageInfo!
                        \SetDamage 10*crashpct
                        \SetAttacker ply
                        \SetDamageType DMG_FALL
                        \SetDamagePosition hit.StartPos
                        \SetDamageForce force
                        --target the head here!
                        ply\TakeDamageInfo dmg
                        if crashpct >= .75
                            ply\SetDSP 36
                            ply\FallOver dmg if ply.FallOver
                        else 
                            ply\SetDSP 35
                    ply\Spasm sequence: anims.headbutt, SS: true
                if hit.Entity and IsValid hit.Entity
                    if hit.Entity\IsPlayer!
                        force\Mul -1
                        if SERVER
                            with dmg = DamageInfo!
                                \SetDamage 20*crashpct
                                \SetAttacker ply
                                \SetDamageType DMG_FALL
                                \SetDamagePosition hit.HitPos
                                \SetDamageForce force
                                --target the head here!
                                hit.Entity\TakeDamageInfo dmg
                                hit.Entity\FallOver dmg if hit.Entity.FallOver and crashpct >= .6
                        hit.Entity\SetSpeedLerp min hit.Entity\GetSpeedTarget!, 150
            true
    Chest:
        mins: Vector -12, -12, 34
        maxs: Vector 10, 10, 64
        Ouch: ->
    Legs:
        mins: Vector -12, -12, 6
        maxs: Vector 12, 12, 32
        Ouch: ->

with FindMetaTable 'Player'
    .Tumbler = (bound=bounds.Chest, mul=1, dir) =>
        attach = @GetAttachment @LookupAttachment bound.attach if bound.attach
        pos = if attach then attach.Pos else @GetPos!
        reach = 20*mul
        unless dir
            vel = @GetVelocity!
            velF = vel\Angle!\Forward!
            if (velF * reach)\Length2D! < 16
                velF = if attach then attach.Ang\Forward! else @GetAngles!\Forward!
            dir = velF
        elseif isangle dir
            dir = dir\Forward!
        dir.z = 0 if abs(ceil(dir.x)) == 0 and abs(ceil(dir.y)) == 0
        TraceHull
            start: pos
            endpos: pos + (dir * reach)
            mask: MASK_PLAYERSOLID 
            mins: bound.mins 
            maxs: bound.maxs
            filter: @RunClass 'GetTraceFilter'
    .FallOver = (dmg) =>
        rag = @CreateRagdoll! if SERVER
    .StandUp = =>
        rag = @GetRagdollEntity!
        return unless IsValid rag
        return if rag\GetVelocity!\Length2D() > 8
        chest = rag\LookupBone 'ValveBiped.Bip01_Spine'
        pos, ang = rag\GetBonePosition chest
        res = pos + ang\Forward! * 8
        if res.y > pos.y 
            @Do ACT.STAND_FRONT 
        else
            @Do ACT.STAND_BACK
        if SERVER
            @RemoveRagdoll!
            @UnSpectate!

hook.Add 'PlayerRagdollCreated', _PKG\GetIdentifier'misadventure', (ply, rag) ->
    ply\SetFallen true
    ply\SetNotSolid true
    ply\SetNoTarget true
    ply\DrawShadow false
    ply\SetMoveType MOVETYPE_NONE
    nil

hook.Add 'PlayerRagdollRemoved', _PKG\GetIdentifier'misadventure', (ply, rag) ->
    ply\SetFallen false
    ply\SetNotSolid false
    ply\SetNoTarget false
    ply\DrawShadow true
    ply\SetMoveType MOVETYPE_WALK
    ply\SetPos ply\GetPos! + Vector 0, 0, 16 if ply\IsStuck!
    vel = Vector!
    vel = rag\GetVelocity! if IsValid rag
    ply\SetLocalVelocity vel
    ply\UnSpectate!
    nil

hook.Add 'SetupMove', _PKG\GetIdentifier'misadventure', (ply, mv, cmd) ->
    return if ply\GetMoveType! == MOVETYPE_NOCLIP
    return if ply\GetMoveType! == MOVETYPE_NONE
    unless ply\GetBody!\IsRagdoll!
        vel = ply\GetVelocity!
        speeds = vel\Length!
        if speeds >= TUMBLE_SOFT
            for bound in *{bounds.Chest, bounds.Head, bounds.Legs}
                hit = ply\Tumbler(bound)
                if hit.Hit
                    return if bound.Ouch hit, ply, speeds