import Create from ents
import Run from hook
with gmod.GetGamemode!
    .InventoryCanRemove = (ply, inv, item) => Run('CanInteract', ply, inv) and inv\CanRemoveItem item
    .InventoryCanAccept = (ply, inv, item, slot) => Run('CanInteract', ply, inv) and inv\CanAcceptItem item, slot
    .InventoryItemChanged = (inv, slot, old, new) =>
        with inv
            owner = \GetOwner!
            hands = owner\GetHands! if owner\IsPlayer! and slot == SLOT_HAND

export class INVENTORY extends ENTITY
    @__entity: 'inventory'
    @Base: 'base_point'
    @Type: 'point'
    @Assign: (ent, index) =>
        @SetParent ent
        @SetOwner ent
        ent\SetNWEntity 'ThingInventory', @
    @Summon: (ent) =>
        assert isentity(ent), 'arg 1 must be an entity'  
        inventory = Create @__barcode
        with inventory
            \Spawn!            
            \Activate!
            \Assign ent
        inventory
    @SetupDataTables: => @NetworkVar 'Entity', i, 'Slot'..i+1 for i=0,31
    @HasSlot: (slot) => slot > 0 and slot <= 32
    @GetSlot: (slot) => @['GetSlot'..slot] @
    @SetSlot: (slot, item) => @['SetSlot'..slot] @, item
    @HasItem: (slot) => IsValid @GetItem slot
    @GetItem: (slot) => @GetSlot slot
    @SetItem: (item, slot) =>
        old = @GetItem slot
        @SetSlot slot, item
        Run 'InventoryItemChanged', @, slot, old, item
    @GetItemSlot: (item) => item\GetInventorySlot!
    @AddItem: (item, slot) =>
        @SetItem item, slot
        with item
            \SetInventoryEntity @
            \SetInventorySlot slot
            \SetParent @
            \SetLocalPos Vector!
            \SetLocalAngles Angle!
            \DrawShadow false
            \SetCollisionGroup COLLISION_GROUP_IN_VEHICLE
            if SERVER
                \GetPhysicsObject!\EnableMotion false
                \SetTrigger false
    @RemoveItem: (item) =>
        return if item\GetInventoryEntity! != @
        @SetItem NULL, item\GetInventorySlot!
    @CanInteract: (ply) => true
    @CanAcceptItem: (item, slot) => not @HasItem slot
    @CanRemoveItem: (item) => true
    @UpdateTransmitState: => TRANSMIT_PVS
    @OnRemove: =>
        return if SHUTTING_DOWN
        for i=1,32
            item = @GetSlot i
            if IsValid item
                item\MoveToWorld item\GetPos!, item\GetAngles!

export class INVENTORY_SLOTTED extends INVENTORY
    @GetLayout: => @GetOwner!\RunClass 'GetInventoryLayout'
    @HasSlot: (slot) => tobool @GetLayout![slot]
    @GetItem: (slot) => @GetSlot @GetLayout![slot]
    @SetItem: (item, slot) => 
        old = @GetItem slot
        @SetSlot @GetLayout![slot], item
        Run 'InventoryItemChanged', @, slot, old, item
    @AddItem: (item, slot) =>
        switch slot
            when SLOT_HAND
                @SetItem item, slot
                with item
                    \SetInventoryEntity @
                    \SetInventorySlot slot
                    \SetParent NULL
                    \DrawShadow true
                    \SetCollisionGroup COLLISION_GROUP_WORLD
                    \AlignToOwner!
                    \GetPhysicsObject!\EnableMotion false
            else
                super item, slot