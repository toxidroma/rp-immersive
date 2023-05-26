require 'class-war',    'https://github.com/toxidroma/class-war'
require 'spasm',        'https://github.com/toxidroma/spasm'
require 'ipr-base',     'https://github.com/Pika-Software/ipr-base'
    --provides BIND, PLYCLASS, WEAPON

include'extension.lua'

import band, bnot from bit
import Run from hook
import abs, min, max from math
import InQuad from math.ease
import find from string
import insert, remove, FlipKeyValues from table
import Wait from timer
import TraceLine, TraceHull, TraceEntity from util

export ACT      = include'act.lua'
export STATE    = include'state.lua'

include'battle.lua'
include'binds.lua'
include'states.lua'
include'stance.lua'

local CROSSHAIR
CROSSHAIR = include'crosshair.lua' if CLIENT

export SIZE_TINY, SIZE_SMALL, SIZE_MEDIUM, SIZE_LARGE, SIZE_HUGE
export SLOT_HAND, SLOT_OUTFIT, SLOT_BELT, SLOT_BACK, SLOT_POCKET1, SLOT_POCKET2

SIZE_TINY = 1
SIZE_SMALL = 2 --pistols
SIZE_MEDIUM = 3 --SMGs
SIZE_LARGE = 4 --rifles
SIZE_HUGE = 5 --oversized, can't stow

SLOT_HAND = 0
SLOT_OUTFIT = 1
SLOT_BELT = 2
SLOT_BACK = 3
SLOT_POCKET1 = 4
SLOT_POCKET2 = 5

include'things.lua'
include'inventory.lua'
include'hands.lua'

include'inertia.lua'
include'misadventure.lua'

with FindMetaTable 'Player'
    .StanceIs = (stance) => @GetStance! == stance
    .Observing  = => @GetObserverMode! > OBS_MODE_NONE
    .GetTargets	=	(range=@BoundingRadius!, addfilter, fatness=.75, compensate) =>
        traces = {}
        filter = @RunClass 'GetTraceFilter'
        if addfilter then
            Add filter, addfilter
        uncompstart = @WorldSpaceCenter!
        if compensate
            @LagCompensation true
        start = @WorldSpaceCenter!
        trace =
            start: start
            endpos: start + self\GetForward! * range
            mins: @OBBMins! * fatness
            maxs: @OBBMaxs! * fatness
            filter: filter
            mask: MASK_SHOT
        tr, ent
        for i=1,20
            tr = TraceHull trace
            ent = tr.Entity
            if IsValid ent
                insert traces, tr
                insert trace.filter, ent
        for i=1,20
            tr = TraceLine trace
            ent = tr.Entity
            if IsValid ent
                insert traces, tr
                insert trace.filter, ent
        if compensate
                @LagCompensation false
        traces
    .GetBody = =>
        if (@GetFallen and @GetFallen!) or not @Alive!
            rag = @GetNW2Entity 'improved-player-ragdolls'
            if rag and rag\IsValid!
                return rag
        @
    .GetHeadPos = =>
        head = @LookupBone 'ValveBiped.Bip01_Head1'
        if head
            head = @GetBonePosition head
        else
            head = @EyePos!
        head
    .IsStuck = =>
        TraceEntity({
            start: @GetPos!
            endpos: @GetPos!
            filter: @RunClass 'GetTraceFilter'
        }, @).StartSolid
    .GetInteractTrace = (range=82) =>
        if CLIENT
            frame = FrameNumber!
            return @InteractTrace if @LastInteractTrace == frame
            @LastInteractTrace = frame
        vo, va = @RunClass 'GetViewOrigin'
        @InteractTrace = TraceHull
                start: vo
                endpos: vo + va\Forward! * range
                mins: Vector -3, -3, -3
                maxs: Vector 3, 3, 3
                filter: @RunClass 'GetTraceFilter'
        @InteractTrace
    
    import ACTS from ACT

    .DoingSomething = =>
        return @GetState! == STATE.ACTING
    .Do = (act, ...) =>
        return if @DoingSomething!
        if isnumber act
            act = ACTS[act]
        @Doing = act @, ...
        return if @Doing\Impossible!
        @AlterState STATE.ACTING
        -- picked up by hands:Think -> STATE_ACTING's Think which is predicted

    import STATES from STATE
    .GetStateTable = => STATES[@GetState!]
    .AlterState = (state, seconds, ent, abrupt) =>
        oldstate = @GetState!
        if oldstate != state and not abrupt
            STATES[oldstate]\Exit @, state
        @SetState state
        @SetStateStart CurTime!
        if seconds
            @SetStateEnd CurTime! + seconds
        else
            @SetStateEnd 0
        if ent
            @SetStateEntity ent
        else
            @SetStateEntity NULL
        if oldstate == state
            STATES[state]\Continue @
        else
            STATES[state]\Enter @, oldstate
    .EndState = (abrupt) =>
        @AlterState STATE.IDLE, nil, nil, abrupt
    .StateIs = (state) => @GetState! == state

hook.Add 'SetupPlayerDataTables', tostring(_PKG), (classy) ->
    with classy
        \NetworkVar 'Int',      'State'
        \NetworkVar 'Int',      'Stance'
        \NetworkVar 'Bool',     'HoldingDown'
        \NetworkVar 'Float',    'StateStart'
        \NetworkVar 'Float',    'StateEnd'
        \NetworkVar 'Float',    'StateNumber'
        \NetworkVar 'Entity',   'StateEntity'
        \NetworkVar 'Vector',   'StateVector'
        \NetworkVar 'Angle',    'StateAngles'
        .Player\SetState STATE.IDLE
        .Player\SetStance STANCE_RISEN
    nil

export FOV, FOV_TARGET = 110, 110

class IMMERSIVE extends PLYCLASS
    DisplayName:        'Immersive Player'
    UseDynamicView:     true
    SlowWalkSpeed:      100
    WalkSpeed:          125
    RunSpeed:           400
    CrouchedWalkSpeed:  60/80

    InventoryLayout: FlipKeyValues {
        SLOT_HAND
        SLOT_OUTFIT
        SLOT_BELT
        SLOT_BACK
        SLOT_POCKET1
        SLOT_POCKET2
    }
    GetInventoryLayout: => @InventoryLayout

    Spawn: => 
        super!
        @Player\Give 'hands'
        @Player\SetCanZoom false
        @Player\AllowFlashlight false
        @Player\SetFallen false
        @Player\CrosshairDisable true
        INVENTORY_SLOTTED\Summon @Player
    Death: => 

    StartCommand: (cmd) => 
        if @Player\GetBody! != @Player
            cmd\ClearMovement!
        elseif @Player.GetState
            if state = @Player\GetStateTable!
                state\StartCommand @Player, cmd if state.StartCommand

    --SHARED
    StartMove: (mv, cmd) => 
        mv\SetButtons band mv\GetButtons!, bnot(IN_JUMP + IN_DUCK)
        return
    FinishMove: (mv) =>
        rag = @Player\GetRagdollEntity!
        if IsValid rag
            @Player\SetPos rag\GetPos!
            rag.lastVelocity = rag\GetVelocity!
            true
    GetViewOrigin: =>
        pos, ang = super!
        if @UseDynamicView
            ent = @Player\GetBody!
            return unless IsValid ent
            head = ent\LookupBone 'ValveBiped.Bip01_Head1'
            if head
                ent\SetupBones! if CLIENT
                matrix = ent\GetBoneMatrix head
                pos, ang = LocalToWorld Vector(5,-5,0), Angle(0,-90,-90), matrix\GetTranslation!, matrix\GetAngles!
                ang = ent\EyeAngles! unless ent\IsRagdoll!
                trace = TraceLine
                    start: @Player\EyePos!
                    endpos: pos
                    filter: @GetTraceFilter!
                    mins: Vector -3, -3, -3
                    maxs: Vector 3, 3, 3
                    collisiongroup: COLLISION_GROUP_PLAYER_MOVEMENT
                pos = trace.HitPos
        pos, ang
    GetTraceFilter: => {@Player, @Player\GetBody!, @Player\Wielding!}
    GetHandPosition: =>
        index = @Player\LookupAttachment 'anim_attachment_RH'
        return super! unless index
        if att = @Player\GetAttachment index
            att.Pos, att.Ang

    --CLIENT
    CalcView: (view) =>
        super view
        FOV_TARGET = 110
        if @UseDynamicView
            view.drawviewer = true
            view.znear = 1
        if CROSSHAIR and CROSSHAIR.TARGET and CROSSHAIR.TARGET.inspection
            FOV_TARGET -= 23
        FOV = Lerp InQuad(FrameTime!*23), FOV, FOV_TARGET
        view.fov = FOV
        view
    PostDrawOpaqueRenderables: => CROSSHAIR\Run LocalPlayer!\GetInteractTrace!
    ShouldDrawLocal: => true
    InputMouseApply: (cmd, x, y, ang) =>
        return if abs(x) + abs(y) <= 0
        if @Player\DoingSomething! and @Player.Doing and @Player.Doing.Immobilizes
            with cmd
                \SetMouseX 0
                \SetMouseY 0
            true
    PreDraw: (ent, flags) =>
        if @Player == LocalPlayer! and @UseDynamicView and (render.IsTrueFirstPerson! or @Player\WaterLevel! >= 2)
            cvar = GetConVar('configurable_view') 
            return if cvar and cvar\GetInt! != 0
            ent\AttemptBoneScale bone, Vector! for bone in *{'ValveBiped.Bip01_Head1', 'ValveBiped.Bip01_Neck1'}
    PostDraw: (ent, flags) =>
        if @UseDynamicView
            cvar = GetConVar('configurable_view') 
            return if cvar and cvar\GetInt! != 0
            ent\AttemptBoneScale bone, Vector 1, 1, 1 for bone in *{'ValveBiped.Bip01_Head1', 'ValveBiped.Bip01_Neck1'}
    PrePlayerDraw: (flags) =>
        return true if IsValid @Player\GetRagdollEntity!
        @PreDraw @Player, flags
    PostPlayerDraw: (flags) => @PostDraw @Player, flags

with gmod.GetGamemode!
    .DoAnimationEvent = (ply, event, data) =>
		return unless ply.GetState and ply.GetStateTable
		state = ply\GetStateTable!
		state\Jumped ply if event == PLAYERANIMEVENT_JUMP
	.CalcMainActivity = (ply, vel) =>
		return unless ply.GetState and ply.GetStateTable
		with ply
			.CalcIdeal = -1
			.CalcSeqOverride = -1
			.m_bWasOnGround     = \IsOnGround!
			.m_bWasNoclipping   = \GetMoveType! == MOVETYPE_NOCLIP and not \InVehicle!

			\GetStateTable!\CalcMainActivity ply, vel
			return .CalcIdeal, .CalcSeqOverride

		--@HandlePlayerLanding ply, vel, ply.m_bWasOnGround

		--unless @HandlePlayerNoClipping(ply, vel)
		--	unless @HandlePlayerDriving(ply)
		--		unless @HandlePlayerVaulting(ply, vel)
		--			unless @HandlePlayerJumping(ply, vel)
		--				unless @HandlePlayerDucking(ply, vel)
		--					unless @HandlePlayerSwimming(ply, vel)
		--						len2d = vel\Length2D!
		--						if len2d > ply\GetRunSpeed() / math.sqrt(2) - 8
		--							ply.CalcIdeal = ACT_MP_RUN
		--						elseif len2d > 0.5
		--							ply.CalcIdeal = ACT_MP_WALK
	.UpdateAnimation = (ply, vel, maxSeqGroundSpeed) =>
		len = vel\Length!
		rate = 1
		if len > .2
			rate = len*.71 / maxSeqGroundSpeed
		rate = min rate, 2
		rate = max rate, .5 if ply\WaterLevel! >= 2
		rate = .1 if ply\IsOnGround! and len >= 1000
		ply\SetPlaybackRate rate
    if CLIENT
        hidden =
            CHudHealth: true
            CHudBattery: true
            CHudAmmo: true
            CHudSecondaryAmmo: true
            CHudCrosshair: true
            CHudHistoryResource: true
            CHudPoisonDamageIndicator: true
            CHudSquadStatus: true
            CHUDQuickInfo: true
            CHudWeaponSelection: true
            
        .HUDShouldDraw = (element) => 
            return false if hidden[element]
            true
    if SERVER
        .PlayerSpawn = (ply) =>
            player_manager.SetPlayerClass(ply, 'player/immersive')
            Run 'PlayerSetModel', ply
            with ply
                \RunClass 'Spawn'
                \CrosshairDisable!
                .Doing\Kill! if .Doing
                \SetCollisionGroup COLLISION_GROUP_PLAYER
        Wait 0, ->
            hook.Add 'PlayerInitialSpawn', tostring(_PKG), (ply) ->
                return if ply\Loaded!
                hook.Add 'SetupMove', tostring(_PKG)..ply\UserID!, (ply2, mv, cmd) ->
                    if ply == ply2 and not cmd\IsForced!
                        hook.Remove 'SetupMove', tostring(_PKG)..ply\UserID!
                        Run 'PlayerInitialized', ply
            hook.Add 'PlayerDisconnected', tostring(_PKG), (ply) ->
                hook.Remove 'SetupMove', tostring(_PKG)..ply\UserID!
        hook.Add 'PlayerInitialized', tostring(_PKG), (ply) ->
            ply\Spawn!
            nil

if CLIENT
    hook.Add 'RenderScene', tostring(_PKG), ->
        ply = LocalPlayer!
        if IsValid ply
            hook.Remove 'RenderScene', tostring(_PKG)
            Run 'PlayerInitialized', ply
        return
    hook.Add 'ShutDown', tostring(_PKG), ->
        hook.Remove 'ShutDown', tostring(_PKG)
        ply = LocalPlayer!
        if IsValid ply
            Run 'PlayerDisconnected', ply
        return

with FindMetaTable 'CMoveData'
    .RemoveKey = (key) =>
        if @KeyDown key
            newbuttons = band @GetButtons!, bnot key
            @SetButtons newbuttons
    .RemoveKeys = (keys) =>
        -- Using bitwise operations to clear the key bits.
        newbuttons = band @GetButtons!, bnot keys
        @SetButtons newbuttons

hook.Add 'AllowPlayerPickup', tostring(_PKG), (ply, ent) -> false

NO = {
    '+use'
    '+voicerecord'
    --'+menu_context' -- there needs to be a bind for the Device
    'messagemode'
    '+zoom'
}

hook.Add 'PlayerBindPress', tostring(_PKG), (ply, bind, down) ->
    if down
        return true if find bind, fuckedoff for fuckedoff in *NO

export class UPLINK_READY extends UPLINK
    @Callback: (ply) => 
        return unless IsValid ply
        return if ply\GetNWBool _PKG\GetIdentifier'loaded'
        ply\SetNWBool _PKG\GetIdentifier'loaded', true
        ply\Spawn!