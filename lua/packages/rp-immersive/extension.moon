with table
    .FlipKeyValues = (tbl) -> {v,k for k,v in pairs tbl}

with timer
    .FindTimer  = (...) -> .Exists ...
    .Wait       = (...) -> .Simple ...
    .NewTimer   = (...) -> .Create ...
    .KillTimer  = (...) -> .Remove ...

if CLIENT
    with render
        .IsTrueFirstPerson = -> GetViewEntity! == LocalPlayer! and not .GetRenderTarget!
        .IsDrawingReflections = -> 
            rt = .GetRenderTarget!
            rt and (rt\GetName! == '_rt_waterreflection' or rt\GetName! == '_rt_waterrefraction') or false

    import NoTexture from draw
    import pi, abs, rad, cos, sin, Clamp from math
    import insert from table
    cache = {}
    with surface
        .DrawCircle = (x, y, radius, passes=100) ->
            id = "#{x}|#{y}|#{radius}|#{passes}"
            info = cache[id]
            unless info
                info = {}
                for i=1,passes+1
                    deg_in_rad = i * pi / (passes*.5)
                    info[i] = {
                        x: x + cos(deg_in_rad)*radius
                        y: y + sin(deg_in_rad)*radius
                    }
                cache[id] = info
            NoTexture!
            .DrawPoly info
        .DrawPie = (pct, x, y, radius, passes=360) ->
            id = "#{pct}|#{x}|#{y}|#{radius}|#{passes}"
            info = cache[id]
            unless info
                info = {}
                startang, endang, step = -90, 360 / 100 * pct - 90, 360 / passes
                if abs(startang, endang) != 0
                    insert info,
                        x: 0
                        y: 0
                for i=startang,endang+step,step
                    i = Clamp i, startang, endang
                    rads = rad id
                    x, y = cos(rads), sin(rads)
                    insert info, 
                        :x
                        :y
                for piece in *info
                    v.x *= radius + x
                    v.y *= radius + y
                cache[id] = info
            NoTexture!
            .DrawPoly info

import TraceLine from util
boneTab = {Pos: Vector!, Ang: Angle!}
attachTab, eyeOffVec, eyeOffAng = {Pos: Vector!, Ang: Angle!}, Vector(0,0,30), Angle(20,0,0)
with FindMetaTable 'Entity'
    --thanks lambda players
    .DistanceFrom = (pos) =>
        pos = pos\GetPos! if isentity pos
        return @GetPos!\Distance pos
    .DistanceFromSqr = (pos) =>
        pos = pos\GetPos! if isentity pos
        return @GetPos!\DistToSqr pos
    .GetBoneTransformation = (bone) =>
        pos, ang = @GetBonePosition bone
        if (not pos) or pos\IsZero! or pos == @GetPos!
            matrix = @GetBoneMatrix bone
            if matrix and ismatrix matrix
                with matrix
                    boneTab = 
                        Pos: \GetTranslation!
                        Ang: \GetAngles!
                return boneTab
        boneTab = 
            Pos: pos
            Ang: ang
        return boneTab
    .GetAttachmentPoint = (pointtype) =>
        switch pointtype
            when 'hand'
                lookup = @LookupAttachment 'anim_attachment_RH'
                if lookup == 0
                    bone = @LookupBone 'ValveBiped.Bip01_R_Hand'
                    unless isnumber bone
                        attachTab =
                            Pos: @WorldSpaceCenter!
                            Ang: @GetForward!\Angle!
                        return attachTab
                    return @GetBoneTransformation bone
                return @GetAttachment lookup
            when 'eyes'
                lookup = @LookupAttachment 'eyes'
                if lookup == 0
                    attachTab =
                        Pos: @WorldSpaceCenter! + eyeOffVec
                        Ang: @GetForward!\Angle! + eyeOffAng
                    return attachTab
                return @GetAttachment lookup
    .CanSee = (ent) =>
        return unless IsValid ent
        tr = TraceLine
            start: @GetAttachmentPoint('eyes').Pos
            endpos: ent\WorldSpaceCenter!
            filter: @
        return tr.Fraction == 1.0 or tr.Entity == ent
    --thanks tanknut
    .AttemptBoneScale = (name, scale, networking) =>
        id = @LookupBone name
        @ManipulateBoneScale id, scale, networking if id