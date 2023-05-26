class IDLE extends STATE
    Think: (ply) => ply\AlterState(STATE.PRIMED) if ply\KeyDown IN_ATTACK2

anims = include'animtable.lua'
class PRIMED extends STATE
    Think: (ply) => ply\EndState! unless ply\KeyDown IN_ATTACK2
    CalcMainActivity:	(ply, vel) => 
        thing = ply\Wielding!
        super ply, vel, 
            if IsValid(thing)
                if BIND.CONTROLS['release']\IsDown ply
                    thing.Animations.throw
                else
                    thing.Animations.prime
            else
                anims.fist
        -- TODO: make this check whatever
        -- is being held in our hands

class ACTING extends STATE
    Enter: (ply, oldstate) => ply.Doing\Do(oldstate) if ply.Doing
    StartCommand: (ply, cmd) =>
        if ply\DoingSomething!
            return ply.Doing\Kill! if ply.Doing\Impossible!
            with cmd
                if ply.Doing.Immobilizes
                    \ClearMovement!
                    return true
            return