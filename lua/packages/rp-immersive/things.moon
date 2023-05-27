gm = gmod.GetGamemode!
import Create from ents
import Run from hook
import random from math
import Empty from table
import TraceHull, TraceLine, GetSurfaceData from util
with gm
    .CanInteract = (ply, ent) => 
        return ent\CanInteract ply if ent.CanInteract
        true
    .ItemAllowMove = (ply, item, inv, slot) =>
        return false unless Run 'CanInteract', ply, item
        oldInv = item\GetInventoryEntity!
        return false if IsValid(oldInv) and not Run 'InventoryCanRemove', ply, oldInv, item
        return false if IsValid(inv) and not Run 'InventoryCanAccept', ply, inv, item, slot
        true

BIND 'release',
        KEY_X, {
            Release: (ply) => ply\Do ACT.DROP, ply\Wielding! unless ply\StateIs STATE.PRIMED
    }

BIND 'item_use',
        MOUSE_MIDDLE, {
            Press: (ply) => ply\Wielding!\Used ply if IsValid(ply\Wielding!) and ply\Wielding!.Used
    }

hook.Add 'LockTarget', tostring(_PKG), (target) ->

with FindMetaTable 'Player'
    .Wielding = => 
        inventory = @GetInventory!
        inventory\GetItem SLOT_HAND if IsValid(inventory) and inventory.GetItem
    .TraceItem = (item, pos, high) =>
        start = @RunClass 'GetViewOrigin'
        local mins, maxs
        with item
            mins, maxs = \GetRotatedAABB \OBBMins!, \OBBMaxs!
        if high
            pos = pos - Vector 0, 0, mins.z
        tr = TraceHull 
            start: start
            endpos: pos
            filter: @RunClass 'GetTraceFilter'
            mins: mins
            maxs: maxs
        tr
    .Release =  (item) =>
        return unless IsValid item
        item\AlignToOwner!
        tr = @TraceItem item, item\WorldSpaceCenter!
        item\MoveToWorld tr.HitPos, item\GetAngles!

with FindMetaTable 'Entity'
    .GetInventory = => @GetNWEntity 'ThingInventory'
    .HasInventory = => IsValid @GetInventory!

anims = include'animtable.lua'
export class THING extends ENTITY
    @__entity: 'thing'
    @SetupDataTables: =>
        @_NetworkVars =
            String: 0
            Bool:   0
            Float:  0
            Int:    0
            Vector: 0
            Angle:  0
            Entity: 0
        @AddNetworkVar 'Entity', 'InventoryEntity'
        @AddNetworkVar 'Int', 'InventorySlot'
    @AddNetworkVar: (varType, name, extended) =>
        index = assert @_NetworkVars[varType], @GetClass!..' Attempt to register unknown network var type ' .. varType
        max = varType == 'String' and 3 or 31
        error 'Network var limit exceeded for '..varType if index >= max
        @NetworkVar varType, index, name, extended
        @_NetworkVars[varType] = index + 1
    @Summon: (where) =>
        thing = Create @__barcode
        if isvector where
            thing\SetPos where
        elseif isentity(where) and where\IsPlayer!
            thing\SetPos where\GetInteractTrace!.HitPos 
        thing\Spawn!
        thing\Activate!
        thing
    @Base: 'base_anim'
    @Type: 'anim'

    @Name: 'thing'
    @Model: Model 'models/props_junk/PopCan01a.mdl'
    @Description: 'Wow! I can pick it up and throw it!'
    @GetDescription: => @Description
    
    @Animations: 
        prime: anims.something
        throw:  anims.throwing

    @HandOffset:
        Pos: Vector!
        Ang: Angle!

    @ImpactSound: 'popcan.impacthard'

    @CanInteract: (ply) => 
        if ply\DoingSomething!
            return @ == ply.Doing.thing
        true
    @OnPrimaryInteract: (tr, ply, hands) =>
    @OnInteract: =>
    @Attack:
        Enabled: true
        Damage: 10
        DamageType: DMG_CLUB
        Delay: .5
        Range: 50

    @SizeClass: SIZE_TINY
    @Mass: 1
    @ThrowVelocity: 1000
    @PlaceAngle: Angle!
    @PlaceAngle2: Angle!

    @Initialize: =>
        @SetModel(@Model)
        if SERVER
            @PhysicsInit SOLID_VPHYSICS
            @SetMoveType MOVETYPE_VPHYSICS
            @SetUseType SIMPLE_USE
            @TouchList = {}
            with phys = @GetPhysicsObject!
                \SetMass @Mass
            @SetCollisionGroup COLLISION_GROUP_WEAPON if @SizeClass <= SIZE_SMALL
        @PhysWake!
        @VisibleState = true

    @CanBeMoved: => true
    @MoveTo: (ply, inv, slot, force) =>
        unless force
            ok = Run 'ItemAllowMove', ply, @, inv, slot
            return false unless ok
        oldInv = @GetInventoryEntity!
        oldInv\RemoveItem @ if IsValid oldInv
        inv\AddItem @, slot
    @MoveToWorld: (pos, ang, force) =>
        oldInv = @GetInventoryEntity!
        oldInv\RemoveItem @ if IsValid oldInv
        @AddToWorld pos, ang
    @AddToWorld: (pos, ang) =>
        @SetCollisionGroup COLLISION_GROUP_WEAPON
        @CreateTouchList! if SERVER and @SizeClass > SIZE_SMALL 
        @SetParent NULL
        @SetInventoryEntity NULL
        if SERVER
            @SetPos pos
            @SetAngles ang
            @GetPhysicsObject!\EnableMotion true
            @PhysWake!
        @UpdateVisible!

    @Think: =>
        @AlignToOwner! if @InHand!
        @RemoveEFlags 61440 if CLIENT and @InWorld! and @IsEFlagSet 61440
        @UpdateTouchList! if SERVER
        --@UpdateVisible!

    @GetHandOffset: => @HandOffset
    @AlignToOwner: =>
        holder = @GetHolder!
        return unless IsValid holder
        pos, ang = holder\RunClass 'GetHandPosition'
        offset = @GetHandOffset!
        pos, ang = LocalToWorld offset.Pos, offset.Ang, pos, ang
        @SetPos pos
        @SetAngles ang
    @GetHolder: =>
        inv = @GetInventoryEntity!
        return inv\GetParent! if IsValid inv
        NULL

    @InHand: => IsValid(@GetInventoryEntity!) and @GetInventorySlot! == SLOT_HAND
    @InInventory: => IsValid(@GetInventoryEntity!) and @GetInventorySlot! != SLOT_HAND
    @InWorld: => not IsValid @GetInventoryEntity!

    @StartTouch: (ent) => if SERVER then @TouchList[ent] = true
    @EndTouch: (ent) => if SERVER then @TouchList[ent] = nil
    @CreateTouchList: => 
        if SERVER
            Empty @TouchList
            @TriggerActive = true
            @SetTrigger true
    @UpdateTouchList: =>
        return if not @TriggerActive or table.Count(@TouchList) > 0
        @TriggerActive = false
        @SetTrigger false
        @SetCollisionGroup COLLISION_GROUP_NONE

    @PhysicsCollide: (data, physobj) => 
        if data.DeltaTime > .2 and data.Speed > 30
            @EmitSound @ImpactSound 
            @SetCollisionGroup COLLISION_GROUP_WEAPON if @SizeClass <= SIZE_SMALL

    @UpdateVisible: =>
        visible = not @InInventory!
        if visible != @VisibleState
            @OnVisibleChanged visible
            @VisibleState = visible
    @GetVisible: => @VisibleState
    @OnVisibleChanged: (visible) =>

    @DrawCustomOpaque: (flags) => if CLIENT then @DrawModel!
    @DrawCustomTranslucent: (flags) => if CLIENT then @DrawModel!
    @Draw: (flags) => 
        if CLIENT
            return if @InInventory!
            @AlignToOwner! if @InHand!
            @SetupBones!
            @DrawCustomOpaque flags
    @DrawTranslucent: (flags) => 
        if CLIENT
            return if @InInventory!
            @AlignToOwner! if @InHand!
            @SetupBones!
            @DrawCustomTranslucent flags

class ThrowThing extends SOUND
    sound: ["dysphoria/whoosh/arm#{i}.ogg" for i=1,30]
    pitch: {70, 90}

class PickupThing extends SOUND
    sound: ["dysphoria/pickup#{i}.ogg" for i=1,5]

class PICK_UP extends ACT
    new: (@ply, @thing) => super @ply
    Immobilizes: false
    Impossible: => true unless IsValid(@thing) and @thing\GetClass!\StartWith'thing' and @ply\DistanceFrom(@thing) <= 82*1.1
    Do: (fromstate) =>
        anim, snd, cycle = 'g_lookatthis', 'PickupThing', .23
        if @ply\EyeAngles!.p >= 45
            anim, cycle = 'pickup_generic_offhand', .5
        @Spasm sequence: anim, SS: true
        @CYCLE cycle, => 
            if SERVER
                with @thing
                    \EmitSound snd
                    \MoveTo @ply, @ply\GetInventory!, SLOT_HAND
            @Kill!

class DROP extends ACT
    new: (@ply, @thing) => super @ply
    Immobilizes: false
    Impossible: => true unless IsValid(@thing) and @ply\Wielding! == @thing
    Do: (fromstate) => @ply\Release @thing

class PLACE extends ACT
    new: (@ply, @thing, @alt) => super @ply
    Immobilizes: false
    Impossible: => true unless IsValid(@thing) and @ply\Wielding! == @thing
    Do: (fromstate) =>
        ang = if @alt then @thing.PlaceAngle2 else @thing.PlaceAngle
        anim, cycle, speed = 'range_slam', .23, 1
        --if @ply\EyeAngles!.p >= 23
        --    anim = 'g_palm_out_r'
        @Spasm sequence: anim, speed: speed, SS: true
        @CYCLE cycle, => 
            if SERVER
                with @thing
                    \SetAngles Angle(0, @ply\GetAngles!.y, 0) + ang
                    tr = @ply\TraceItem @thing, @ply\GetInteractTrace!.HitPos
                    \MoveToWorld tr.HitPos, \GetAngles!
                    start = \GetPos!
                    endpos = start - Vector(0,0,3)
                    tr = TraceLine 
                        start: start
                        endpos: endpos
                        filter: @thing
                    unless tr.Hit
                        tr = TraceLine 
                            start: start
                            endpos: start
                    surfprop = GetSurfaceData tr.SurfaceProps
                    surfprop or= GetSurfaceData 0
                    snd = surfprop.impactSoftSound
                    \EmitSound snd
            @Kill!

class THROW extends ACT
    new: (@ply, @thing, @mult=1) => super @ply
    Immobilizes: false
    Impossible: => true unless IsValid(@thing) and @ply\Wielding! == @thing
    Do: (fromstate) =>
        anim, snd, cycle = 'gesture_throw_grenade', 'ThrowThing', .25
        @Spasm sequence: anim, SS: true
        @CYCLE cycle, => 
            if IsFirstTimePredicted! and SERVER
                @ply\Release @thing
                @thing\EmitSound snd
                vel = @thing.ThrowVelocity
                @thing\SetCollisionGroup COLLISION_GROUP_PLAYER
                with @thing\GetPhysicsObject!
                    \SetVelocity @ply\GetVelocity! + (@ply\GetForward! + Vector 0, 0, .1) * @thing.ThrowVelocity * @mult
                    \AddAngleVelocity Vector(vel, random(-vel, vel), 0) unless @thing.SizeClass == SIZE_HUGE