--hands
class HANDS extends WEAPON
    @WorldModel: ''
    @SetupDataTables: =>
        @NetworkVar 'Float', 0, 'NextInteraction'
        @NetworkVar 'Float', 1, 'LastThrow'
        @NetworkVar 'Bool', 0, 'Throw'
        @NetworkVar 'Bool', 1, 'Raised'
    @Think: =>
        ply = @GetOwner!
        with ply
            \GetStateTable!\Think ply
            .Doing\Think! if .Doing
        thing = ply\Wielding!
        if CLIENT
            if IsValid thing
                return if true
                @RenderGroup = thing\GetRenderGroup!
                @WorldModel = thing\GetModel!
    @PrimaryAttack: =>
        ply = @GetOwner!
        thing = ply\Wielding!
        tr = ply\GetInteractTrace!
        ent = tr.Entity
        if IsValid thing
            if BIND.CONTROLS['release']\IsDown ply
                return if ply\StateIs STATE.PRIMED
                    ply\Do ACT.THROW, thing 
                else 
                    ply\Do ACT.PLACE, thing
            if thing\OnPrimaryInteract tr, ply, @
                return
            ent\OnActUpon ply, @, thing if IsValid(ent) and ent.OnActUpon
        else
            return unless IsValid ent
            return ent\ActUpon ply, @ if ent.ActUpon
            ply\Do ACT.PICK_UP, ent 
    @SecondaryAttack: =>
    @HeldItemChanged: (old, new) => 
        old\SetPredictable false if CLIENT and IsValid old
        new\SetPredictable true if CLIENT and IsValid new

with FindMetaTable 'Player'
    .GetHands = => @GetWeapon 'hands'