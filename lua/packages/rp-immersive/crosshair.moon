import NoTexture from draw
import Run from hook
import sin, cos, min, max, abs, NormalizeAngle, Approach, Clamp from math
import InQuad, InQuint, OutQuint, InSine from math.ease
import IsTrueFirstPerson, SetMaterial, DrawQuadEasy,
    ClearStencil, SetStencilEnable, UpdateScreenEffectTexture,
    SetStencilCompareFunction, SetStencilTestMask, SetStencilWriteMask,
    SetStencilReferenceValue, SetStencilFailOperation, SetStencilZFailOperation from render
import StartWith from string
import SetDrawColor, DrawRect, DrawLine, DrawCircle from surface
import HasFocus from system
import insert, remove, FlipKeyValues from table
import TraceLine, QuickTrace from util

local CROSSHAIR
class SHADOW
    new: (@normal) =>
        CROSSHAIR.nextShadow = CurTime! + .666
        @size = 5
        @[copiedKey] = CROSSHAIR[copiedKey] for copiedKey in *{
            'mat'
            'pos'
            'alpha'
            'color'
            'rotation'
        }
        insert CROSSHAIR.shadows, @
    Drift: =>
        SetMaterial @mat
        DrawQuadEasy @pos, @normal, @size, @size, @color, @rotation
        ft = FrameTime!
        @rotation += ft*sin(CurTime!*.23)*66.666
        @size += ft
        driftspeed = 6.66
        @pos = @pos + Vector(1*ft*driftspeed, 1*ft*driftspeed, 1*ft*driftspeed) * @normal
        @color.a = Approach @color.a, 0, ft*66
        true if @color.a <= 0

export class CROSSHAIR
    @alpha:         0
    @pos:           Vector!
    @mat:           Material'eclipse/game-icons/select.png'
    @rotation:      0
    @shadows:       {}
    @TARGET:        {entity: NULL, fxMul: 0}  
    @Run:           (tr) =>
        return unless HasFocus!
        SetMaterial @mat
        with tr
            dist = .StartPos\Distance(@pos)
            if dist > 666
                @pos = .HitPos 
                dist = 0
            alphaTarget = 102-dist
            alphaTarget = min 255, alphaTarget + 1.23 if @TARGET.locked
            @alpha = max 0, Lerp FrameTime!*66, @alpha, alphaTarget
            @color = Color 255, 255, 255, @alpha
            if IsValid(.Entity) and .Entity\GetClass!\StartWith 'thing'
                unless @TARGET.locked
                    if @TARGET.entity != .Entity
                        @TARGET.showtime = CurTime! + 1
                        @TARGET.entity = .Entity
                    elseif CurTime! >= @TARGET.showtime
                        @LockTarget!
            elseif @TARGET.forgettime and CurTime! >= @TARGET.forgettime
                @TARGET.entity = NULL
                @TARGET.forgettime = nil
            normal = .HitNormal
            normal = -.Normal if normal.x == 0 and normal.y == 0 and normal.z == 0
            @pos = LerpVector InQuad(FrameTime!*42), @pos, .HitPos + Vector(1,1,1) * normal
            vel = LocalPlayer!\GetVelocity!
            len = vel\Length!
            @rotation = NormalizeAngle @rotation + vel\GetNormalized!\Dot(EyeAngles!\Right!) * min(10, len/200)/5
            DrawQuadEasy @pos, normal, 5, 5, @color, @rotation
            @nextShadow or= CurTime!
            SHADOW normal if CurTime! >= @nextShadow
            if .Entity != @TARGET.entity
                @LoseTarget!
        for i, shadow in ipairs @shadows
            unless shadow.Drift
                remove @shadows, i 
            else
                remove @shadows, i if shadow\Drift!
    @LockTarget:    =>  
        if ret = Run 'LockTarget', @TARGET
            return ret
        @TARGET.locked = true
        --if @TARGET.entity\GetClass!\StartWith 'thing'
            --@TARGET.notice = NOTICE {
            --    text: "<font=CloseCaption_Bold>#{@TARGET.entity.Name}\n<font=CloseCaption_Normal>#{@TARGET.entity\GetDescription!}"
            --    duration: 3
            --    Perpetual: -> @TARGET and @TARGET.locked
            --}
    @LoseTarget:    => 
        @TARGET.locked = false
        @TARGET.forgettime = CurTime! + 2.23
        --@TARGET.notice\Kill! if @TARGET.notice

hook.Add 'InputMouseApply', _PKG\GetIdentifier'crosshair', (cmd, x, y, ang) ->
    axis = x
    if abs(y) > abs(x)
        axis = y
    axis /= 6.66
    CROSSHAIR.rotation += axis
    CROSSHAIR.rotation = NormalizeAngle CROSSHAIR.rotation
hook.Add 'PreDrawHalos', _PKG\GetIdentifier'crosshair', ->
    if CROSSHAIR.TARGET.locked
        halo.Add {CROSSHAIR.TARGET.entity}, Color(200, 200, 200), abs(1.666*sin(CurTime!)), abs(1.666*sin(CurTime!)), 10
hook.Add 'RenderScreenspaceEffects', _PKG\GetIdentifier'crosshair', ->
    ply = LocalPlayer!
    if TARGET = CROSSHAIR.TARGET
        if TARGET.inspection
            --DrawBokehDOF unpack CROSSHAIR .DOF
            --eyepos = EyePos!
            --real = RealTime!
            ----vOffset = Vector sin(real)*8, cos(real)*8, sin(CurTime!)*8
            --pos = TARGET.entity\LocalToWorld(TARGET.entity\OBBCenter!) --+ vOffset
            --dist = eyepos\Distance pos
            --dot = (pos - eyepos)\GetNormalized!\Dot(EyeVector!) - dist * .0005
            --if dot > 0
            --    srcpos = pos\ToScreen!
            --    DrawSunbeams(TARGET.sunblock, dot * -2.3, .0666, srcpos.x / ScrW!, srcpos.y / ScrH!)
            TARGET.fxMul = Lerp FrameTime!*13, TARGET.fxMul, 1
        else
            TARGET.fxMul = Lerp FrameTime!*13, TARGET.fxMul, 0
        DrawToyTown 6*TARGET.fxMul, 666*TARGET.fxMul

return CROSSHAIR