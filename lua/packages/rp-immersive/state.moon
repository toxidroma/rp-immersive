import upper from string
import insert from table
anims   = include'animtable.lua'
class
    @STATES: {}
	@__inherited: (child) => @[upper child.__name] = insert @STATES, child
    Think: 				(ply) =>
    Enter: 				(ply, oldstate) =>
    Continue:		 	(ply) =>
    Exit:				(ply, newstate) =>
    Move:				(ply, mv) =>
    HandleMidair:		(ply, vel, animset) =>
        with ply
            if .Jumping
                if .FirstJumpFrame
                    .FirstJumpFrame = false
                    \AnimRestartMainSequence!
                if \WaterLevel! >= 2
                    .Jumping = false
                    \AnimRestartMainSequence!
                unless .Landing
                    if (CurTime! - .JumpStart) > .4 and \OnGround!
                        .Landing = true
                        .LandStart = CurTime!
                        if CLIENT then \Spasm 'jump_land'
                        --for foot=0,1 do
                            --hook.Run "PlayerFootstep", ply, \GetPos!, foot, "common/null.wav", 1
                        return true
                elseif (CurTime! - .LandStart) > .3
                    .Landing = false
                    .Jumping = false
                if .Jumping and not .Landing
                    .CalcSeqOverride = \FindSequence animset.jump
                    return true
        false
    CalcMainActivity: 	(ply, vel, animset) =>
        animset = anims.normal unless animset
        return if @HandleMidair ply, vel, animset
        if @HandleSquat
            return if @HandleSquat ply, vel, animset
        if @HandleProne
            return if @HandleProne ply, vel, animset
        len2d = vel\Length2D!
        with ply
            .CalcSeqOverride = \FindSequence animset.idle
            if (len2d > \ClassTable!.WalkSpeed / math.sqrt(2) - 8) and ply\KeyDown IN_SPEED
                .CalcSeqOverride = \FindSequence animset.run
            elseif len2d > 0.5
                .CalcSeqOverride = \FindSequence animset.walk
    Jumped:				(ply) =>
        with ply
            .Jumping = true
            .Landing = false
            .FirstJumpFrame = true
            .JumpStart = CurTime!
            \AnimRestartMainSequence!
            if( CLIENT and IsFirstTimePredicted! ) then
                --emit pain sound
                \ViewPunch Angle -5, 0, 0