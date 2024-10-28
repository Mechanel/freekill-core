-- SPDX-License-Identifier: GPL-3.0-or-later

-- AI base class.
-- Do nothing.

---@class AI: Object
---@field public room Room
---@field public player ServerPlayer
---@field public command string
---@field public data any
---@field public handler ReqActiveSkill 可能空，但是没打问号（免得一堆警告）
local AI = class("AI")

function AI:initialize(player)
  ---@diagnostic disable-next-line
  self.room = RoomInstance
  self.player = player
end

-- activeSkill, responseCard, useCard, playCard 四巨头专属
function AI:isInDashboard()
  if not (self.handler and self.handler:isInstanceOf(Fk.request_handlers["AskForUseActiveSkill"])) then
    fk.qWarning("请检查是否在AI中调用了专属于dashboard操作的一系列函数")
    fk.qWarning(debug.traceback())
    return false
  end
  return true
end

--- 返回当前手牌区域内（包含展开的pile）中所有可选且未选中的卡牌 返回ids
---@param pattern string? 可以带一个过滤条件
---@return integer[]
function AI:getEnabledCards(pattern)
  if not self:isInDashboard() then return Util.DummyTable end

  local ret = {}
  for cid, item in pairs(self.handler.scene:getAllItems("CardItem")) do
    if item.enabled and not item.selected then
      if (not pattern) or Exppattern:Parse(pattern):match(Fk:getCardById(cid)) then
        table.insert(ret, cid)
      end
    end
  end
  return ret
end

--- 返回当前所有可选并且还未选中的角色，包括自己
---@return ServerPlayer[]
function AI:getEnabledTargets()
  if not self:isInDashboard() then return Util.DummyTable end
  local room = self.room

  local ret = {}
  for pid, item in pairs(self.handler.scene:getAllItems("Photo")) do
    if item.enabled and not item.selected then
      table.insert(ret, room:getPlayerById(pid))
    end
  end
  return ret
end

--- 获取技能面板中所有可以按下的技能按钮
---@return string[]
function AI:getEnabledSkills()
  if not self:isInDashboard() then return Util.DummyTable end

  local ret = {}
  for name, item in pairs(self.handler.scene:getAllItems("SkillButton")) do
    if item.enabled and not item.selected then
      table.insert(ret, name)
    end
  end
  return ret
end

---@return integer[]
function AI:getSelectedCards()
  if not self:isInDashboard() then return Util.DummyTable end
  return self.handler.pendings
end

---@return ServerPlayer[]
function AI:getSelectedTargets()
  if not self:isInDashboard() then return Util.DummyTable end
  return table.map(self.handler.selected_targets, function(pid)
    return self.room:getPlayerById(pid)
  end)
end

function AI:getSelectedSkill()
  if not self:isInDashboard() then return nil end
  return self.handler.skill_name
end

function AI:selectCard(cid, selected)
  if not self:isInDashboard() then return end
  self.handler:update("CardItem", cid, "click", { selected = selected })
end

---@param player ServerPlayer
function AI:selectTarget(player, selected)
  if not self:isInDashboard() then return end
  self.handler:update("Photo", player.id, "click", { selected = selected })
end

function AI:selectSkill(skill_name, selected)
  if not self:isInDashboard() then return end
  self.handler:update("SkillButton", skill_name, "click", { selected = selected })
end

function AI:okButtonEnabled()
  if not self:isInDashboard() then return false end
  return self.handler:feasible()
end

function AI:doOKButton()
  if not self:isInDashboard() then return end
  if not self:okButtonEnabled() then return "" end
  return self.handler:doOKButton()
end

function AI:makeReply()
  Self = self.player
  local fn = self["handle" .. self.command]
  local ret = "__cancel"
  if fn then
    local handler_class = Fk.request_handlers[self.command]
    if handler_class then
      self.handler = handler_class:new(self.player, self.data)
      self.handler:setup()
    end
    ret = fn(self, self.data)
  end
  if ret == "" then ret = "__cancel" end
  self.handler = nil
  return ret
end

return AI
