require 'class-war', 'https://github.com/toxidroma/class-war'
require 'ipr-base', 'https://github.com/Pika-Software/ipr-base'
    --provides PLYCLASS
import TraceLine, TraceHull, TraceEntity from util
import band, bnot from bit

with FindMetaTable 'Player'
    .GetBody = =>
        unless @Alive!
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

class IMMERSIVE extends PLYCLASS
    DisplayName:        'Immersive Player'
    UseDynamicView:     true
    SlowWalkSpeed:      100
    WalkSpeed:          125
    RunSpeed:           400
    CrouchedWalkSpeed:  60/80

    --SHARED
    StartMove: (mv, cmd) => 
        mv\SetButtons band mv\GetButtons!, bnot(IN_JUMP + IN_DUCK)
        return
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

    --CLIENT
    --CalcView: (view) => view.drawviewer = true
    ShouldDrawLocal: => true