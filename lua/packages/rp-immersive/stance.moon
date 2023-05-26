anims = include'animtable.lua'
import upper from string
import insert from table
export HULL_HUMAN_MIN          = Vector -16, -16, 0
export HULL_HUMAN_MAX_SQUAT    = Vector 16, 16, 36
export HULL_HUMAN_MAX_PRONE    = Vector 16, 16, 20
export STANCE_RISEN, STANCE_SQUAT, STANCE_PRONE = 1, 2, 3
class STANCE extends ACT
    @__inherited: (child) =>
        STANCE[upper child.__name] = super child
class RISEN extends STANCE
    Do: =>
        with @ply
            return if \StanceIs STANCE_RISEN
            anims = 
                [STANCE_SQUAT]: 'crouch_to_stand'
                [STANCE_PRONE]: 'proneup_stand'
            @Spasm sequence: anims[\GetStance!]
            \SetStance STANCE_RISEN
            \ResetHull!
            \SetHoldingDown false
class SQUAT extends STANCE
    Do: =>
        with @ply
            return if \StanceIs STANCE_SQUAT
            anims = 
                [STANCE_RISEN]: 'stand_to_crouch'
                [STANCE_PRONE]: 'proneup_crouch'
            @Spasm sequence: anims[\GetStance!]
            \SetStance STANCE_SQUAT
            \SetHull HULL_HUMAN_MIN, HULL_HUMAN_MAX_SQUAT
            \SetHoldingDown false
    Then: =>
        super!
        if BIND.CONTROLS['ctrl']\IsDown @ply
            @ply\SetHoldingDown true
class PRONE extends STANCE
    Do: =>
        with @ply
            return if \StanceIs STANCE_PRONE
            anims = 
                [STANCE_RISEN]: 'pronedown_stand'
                [STANCE_SQUAT]: 'pronedown_crouch'
            @Spasm sequence: anims[\GetStance!]
            \SetStance STANCE_PRONE
            \SetHull HULL_HUMAN_MIN, HULL_HUMAN_MAX_PRONE
            \SetHoldingDown false
    Then: =>
        super!
        if BIND.CONTROLS['space']\IsDown @ply
            @ply\SetHoldingDown true

with STATE
    .HandleSquat =		(ply, vel, animset) =>
        with ply
            if \StanceIs STANCE_SQUAT
                .CalcSeqOverride = 	\FindSequence vel\Length2D! > .5 and animset.creep or animset.squat
                if \GetHoldingDown!
                    unless \DoingSomething! or BIND.CONTROLS['ctrl']\IsDown ply
                        \Do ACT.STANCE_RISEN
                return true
        false
    .HandleProne =		(ply, vel, animset) =>
        with ply
            if \StanceIs STANCE_PRONE
                .CalcSeqOverride = 	\FindSequence vel\Length2D! > .5 and animset.crawl or animset.prone
                if \GetHoldingDown!
                    unless \DoingSomething! or BIND.CONTROLS['space']\IsDown ply
                        \Do ACT.STANCE_RISEN
                return true
        false