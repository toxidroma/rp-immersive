import upper from string
import insert from table
class
    @ACTS: {}
    @__inherited: (child) => 
        name = child.__name
        if @ != ACT
            name = @__name..'_'..name
        ACT[upper name] = insert @ACTS, child
        return #@ACTS
    new: (@ply) => @events = {}
    Do: =>
    Then: => @Kill!
    Impossible: => false
    Spasm: (choreo) => 
        choreo.slot = choreo.slot or GESTURE_SLOT_CUSTOM
        @sequence   = @ply\FindSequence choreo.sequence
        unless choreo.speed
            choreo.speed = 1
        @speed      = choreo.speed
        @slot       = choreo.slot
        @ply\Spasm choreo
    Kill: => 
        @ply.Doing = nil
        if @ply\KeyDown IN_ATTACK2
            @ply\AlterState(STATE.PRIMED) 
        else
            @ply\EndState!
        true
    EmitSound: (...) => 
        if IsFirstTimePredicted!
            @ply\GetActiveWeapon!\EmitSound ...
    CYCLE: (cycle, func) => insert @events, {cycle, func}
    Think: =>
        return @Kill! unless @ply and IsValid @ply
        if @sequence and @slot
            events = {}
            if @events
                for event in *@events
                    if event[1] < @ply\GetLayerCycle @slot
                        event[2] @
                    else
                        insert events, event
                @events = events
            if @Then
               @Then! if @ply\GetLayerSequence(@slot) != @sequence
    Immobilizes: true