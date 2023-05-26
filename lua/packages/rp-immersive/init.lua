require('class-war', 'https://github.com/toxidroma/class-war')
require('spasm', 'https://github.com/toxidroma/spasm')
require('ipr-base', 'https://github.com/Pika-Software/ipr-base')
include('extension.lua')
local band, bnot
do
  local _obj_0 = bit
  band, bnot = _obj_0.band, _obj_0.bnot
end
local abs, min, max
do
  local _obj_0 = math
  abs, min, max = _obj_0.abs, _obj_0.min, _obj_0.max
end
local insert, remove, FlipKeyValues
do
  local _obj_0 = table
  insert, remove, FlipKeyValues = _obj_0.insert, _obj_0.remove, _obj_0.FlipKeyValues
end
local TraceLine, TraceHull, TraceEntity
do
  local _obj_0 = util
  TraceLine, TraceHull, TraceEntity = _obj_0.TraceLine, _obj_0.TraceHull, _obj_0.TraceEntity
end
ACT = include('act.lua')
STATE = include('state.lua')
include('battle.lua')
include('binds.lua')
include('states.lua')
include('stance.lua')
local CROSSHAIR
if CLIENT then
  CROSSHAIR = include('crosshair.lua')
end
SIZE_TINY = 1
SIZE_SMALL = 2
SIZE_MEDIUM = 3
SIZE_LARGE = 4
SIZE_HUGE = 5
SLOT_HAND = 0
SLOT_OUTFIT = 1
SLOT_BELT = 2
SLOT_BACK = 3
SLOT_POCKET1 = 4
SLOT_POCKET2 = 5
include('things.lua')
include('inventory.lua')
include('hands.lua')
do
  local _with_0 = FindMetaTable('Player')
  _with_0.StanceIs = function(self, stance)
    return self:GetStance() == stance
  end
  _with_0.Observing = function(self)
    return self:GetObserverMode() > OBS_MODE_NONE
  end
  _with_0.GetTargets = function(self, range, addfilter, fatness, compensate)
    if range == nil then
      range = self:BoundingRadius()
    end
    if fatness == nil then
      fatness = .75
    end
    local traces = { }
    local filter = self:RunClass('GetTraceFilter')
    if addfilter then
      Add(filter, addfilter)
    end
    local uncompstart = self:WorldSpaceCenter()
    if compensate then
      self:LagCompensation(true)
    end
    local start = self:WorldSpaceCenter()
    local trace = {
      start = start,
      endpos = start + self:GetForward() * range,
      mins = self:OBBMins() * fatness,
      maxs = self:OBBMaxs() * fatness,
      filter = filter,
      mask = MASK_SHOT
    }
    local _ = tr, ent
    for i = 1, 20 do
      local tr = TraceHull(trace)
      local ent = tr.Entity
      if IsValid(ent) then
        insert(traces, tr)
        insert(trace.filter, ent)
      end
    end
    for i = 1, 20 do
      local tr = TraceLine(trace)
      local ent = tr.Entity
      if IsValid(ent) then
        insert(traces, tr)
        insert(trace.filter, ent)
      end
    end
    if compensate then
      self:LagCompensation(false)
    end
    return traces
  end
  _with_0.GetBody = function(self)
    if not (self:Alive()) then
      local rag = self:GetNW2Entity('improved-player-ragdolls')
      if rag and rag:IsValid() then
        return rag
      end
    end
    return self
  end
  _with_0.GetHeadPos = function(self)
    local head = self:LookupBone('ValveBiped.Bip01_Head1')
    if head then
      head = self:GetBonePosition(head)
    else
      head = self:EyePos()
    end
    return head
  end
  _with_0.IsStuck = function(self)
    return TraceEntity({
      start = self:GetPos(),
      endpos = self:GetPos(),
      filter = self:RunClass('GetTraceFilter')
    }, self).StartSolid
  end
  _with_0.GetInteractTrace = function(self, range)
    if range == nil then
      range = 82
    end
    if CLIENT then
      local frame = FrameNumber()
      if self.LastInteractTrace == frame then
        return self.InteractTrace
      end
      self.LastInteractTrace = frame
    end
    local vo, va = self:RunClass('GetViewOrigin')
    self.InteractTrace = TraceHull({
      start = vo,
      endpos = vo + va:Forward() * range,
      mins = Vector(-3, -3, -3),
      maxs = Vector(3, 3, 3),
      filter = self:RunClass('GetTraceFilter')
    })
    return self.InteractTrace
  end
  local ACTS
  ACTS = ACT.ACTS
  _with_0.DoingSomething = function(self)
    return self.Doing and self:GetState() == STATE.ACTING
  end
  _with_0.Do = function(self, act, ...)
    if self:DoingSomething() then
      return 
    end
    if isnumber(act) then
      act = ACTS[act]
    end
    self.Doing = act(self, ...)
    if self.Doing:Impossible() then
      return 
    end
    return self:AlterState(STATE.ACTING)
  end
  local STATES
  STATES = STATE.STATES
  _with_0.GetStateTable = function(self)
    return STATES[self:GetState()]
  end
  _with_0.AlterState = function(self, state, seconds, ent, abrupt)
    local oldstate = self:GetState()
    if oldstate ~= state and not abrupt then
      STATES[oldstate]:Exit(self, state)
    end
    self:SetState(state)
    self:SetStateStart(CurTime())
    if seconds then
      self:SetStateEnd(CurTime() + seconds)
    else
      self:SetStateEnd(0)
    end
    if ent then
      self:SetStateEntity(ent)
    else
      self:SetStateEntity(NULL)
    end
    if oldstate == state then
      return STATES[state]:Continue(self)
    else
      return STATES[state]:Enter(self, oldstate)
    end
  end
  _with_0.EndState = function(self, abrupt)
    return self:AlterState(STATE.IDLE, nil, nil, abrupt)
  end
  _with_0.StateIs = function(self, state)
    return self:GetState() == state
  end
end
hook.Add('SetupPlayerDataTables', tostring(_PKG), function(classy)
  do
    classy:NetworkVar('Int', 'State')
    classy:NetworkVar('Int', 'Stance')
    classy:NetworkVar('Bool', 'HoldingDown')
    classy:NetworkVar('Float', 'StateStart')
    classy:NetworkVar('Float', 'StateEnd')
    classy:NetworkVar('Float', 'StateNumber')
    classy:NetworkVar('Entity', 'StateEntity')
    classy:NetworkVar('Vector', 'StateVector')
    classy:NetworkVar('Angle', 'StateAngles')
    classy.Player:SetState(STATE.IDLE)
    classy.Player:SetStance(STANCE_RISEN)
  end
  return nil
end)
local IMMERSIVE
do
  local _class_0
  local _parent_0 = PLYCLASS
  local _base_0 = {
    DisplayName = 'Immersive Player',
    UseDynamicView = true,
    SlowWalkSpeed = 100,
    WalkSpeed = 125,
    RunSpeed = 400,
    CrouchedWalkSpeed = 60 / 80,
    InventoryLayout = FlipKeyValues({
      SLOT_HAND,
      SLOT_OUTFIT,
      SLOT_BELT,
      SLOT_BACK,
      SLOT_POCKET1,
      SLOT_POCKET2
    }),
    GetInventoryLayout = function(self)
      return self.InventoryLayout
    end,
    Loadout = function(self)
      return self.Player:Give('hands')
    end,
    Spawn = function(self)
      _class_0.__parent.__base.Spawn(self)
      self.Player:SetCanZoom(false)
      self.Player:AllowFlashlight(false)
      self.Player:DetachRagdoll()
      return INVENTORY_SLOTTED:Summon(self.Player)
    end,
    Death = function(self) end,
    StartCommand = function(self, cmd)
      if self.Player:GetBody() ~= self.Player then
        return cmd:ClearMovement()
      elseif self.Player.GetState then
        do
          local state = self.Player:GetStateTable()
          if state then
            if state.StartCommand then
              return state:StartCommand(self.Player, cmd)
            end
          end
        end
      end
    end,
    StartMove = function(self, mv, cmd)
      mv:SetButtons(band(mv:GetButtons(), bnot(IN_JUMP + IN_DUCK)))
    end,
    GetViewOrigin = function(self)
      local pos, ang = _class_0.__parent.__base.GetViewOrigin(self)
      if self.UseDynamicView then
        local ent = self.Player:GetBody()
        if not (IsValid(ent)) then
          return 
        end
        local head = ent:LookupBone('ValveBiped.Bip01_Head1')
        if head then
          if CLIENT then
            ent:SetupBones()
          end
          local matrix = ent:GetBoneMatrix(head)
          pos, ang = LocalToWorld(Vector(5, -5, 0), Angle(0, -90, -90), matrix:GetTranslation(), matrix:GetAngles())
          if not (ent:IsRagdoll()) then
            ang = ent:EyeAngles()
          end
          local trace = TraceLine({
            start = self.Player:EyePos(),
            endpos = pos,
            filter = self:GetTraceFilter(),
            mins = Vector(-3, -3, -3),
            maxs = Vector(3, 3, 3),
            collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
          })
          pos = trace.HitPos
        end
      end
      return pos, ang
    end,
    PostDrawOpaqueRenderables = function(self)
      return CROSSHAIR:Run(LocalPlayer():GetInteractTrace())
    end,
    ShouldDrawLocal = function(self)
      return true
    end,
    InputMouseApply = function(self, cmd, x, y, ang)
      if abs(x) + abs(y) <= 0 then
        return 
      end
      if self.Player:DoingSomething() and self.Player.Doing.Immobilizes then
        do
          cmd:SetMouseX(0)
          cmd:SetMouseY(0)
        end
        return true
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "IMMERSIVE",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  IMMERSIVE = _class_0
end
do
  local _with_0 = gmod.GetGamemode()
  _with_0.DoAnimationEvent = function(self, ply, event, data)
    if not (ply.GetState and ply.GetStateTable) then
      return 
    end
    local state = ply:GetStateTable()
    if event == PLAYERANIMEVENT_JUMP then
      return state:Jumped(ply)
    end
  end
  _with_0.CalcMainActivity = function(self, ply, vel)
    if not (ply.GetState and ply.GetStateTable) then
      return 
    end
    do
      local _with_1 = ply
      _with_1.CalcIdeal = -1
      _with_1.CalcSeqOverride = -1
      _with_1.m_bWasOnGround = _with_1:IsOnGround()
      _with_1.m_bWasNoclipping = _with_1:GetMoveType() == MOVETYPE_NOCLIP and not _with_1:InVehicle()
      _with_1:GetStateTable():CalcMainActivity(ply, vel)
      return _with_1.CalcIdeal, _with_1.CalcSeqOverride
    end
  end
  _with_0.UpdateAnimation = function(self, ply, vel, maxSeqGroundSpeed)
    local len = vel:Length()
    local rate = 1
    if len > .2 then
      rate = len * .71 / maxSeqGroundSpeed
    end
    rate = min(rate, 2)
    if ply:WaterLevel() >= 2 then
      rate = max(rate, .5)
    end
    if ply:IsOnGround() and len >= 1000 then
      rate = .1
    end
    return ply:SetPlaybackRate(rate)
  end
  return _with_0
end
