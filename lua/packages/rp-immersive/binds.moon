BIND 'ctrl',
    KEY_LCONTROL, {
        Press: (ply) =>
            with ply
                body = \GetBody!
                return if body\IsRagdoll!
                if \OnGround!
                    unless \DoingSomething!
                        if SERVER or (CLIENT and IsFirstTimePredicted!)
                            unless \StanceIs STANCE_SQUAT
                                \Do ACT.STANCE_SQUAT
                            else
                                \Do ACT.STANCE_RISEN
    }
BIND 'space',
    KEY_SPACE, {
        Press: (ply) =>
            with ply
                if ply\Alive!
                    return \StandUp! if .StandUp and IsValid ply\GetRagdollEntity!
                if \OnGround!
                    unless \DoingSomething!
                        if SERVER or (CLIENT and IsFirstTimePredicted!)
                            unless \StanceIs STANCE_PRONE
                                if \StanceIs STANCE_SQUAT
                                    \Do ACT.STANCE_PRONE
                                else
                                    if BIND.CONTROLS['shift']\IsDown ply
                                        \Do ACT.KICK
                                    else
                                        \Do ACT.SHOVE
                            else
                                \Do ACT.STANCE_RISEN
    }
BIND 'shift',
    KEY_LSHIFT, {
        Press: (ply) =>
            --with ply
            --	if \OnGround!
            --		unless \DoingSomething!
            --			-- do something here
    }