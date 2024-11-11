--- 关于某个技能如何在AI中处理。
---
--- 相关方法分为三类，分别是如何搜索、如何计算收益、如何进行收益推理
---
--- 所谓搜索，就是如何确定下一步该选择哪张卡牌/哪名角色等。
--- 默认情况下，AI选择收益最高的选项作为下一步，如果遇到了死胡同就返回考虑下一种。
--- 所谓死胡同就是什么都不能点击，也不能点确定的状态，必须取消某些的选择。
---
--- 所谓的收益计算就是估算这个选项在这个技能的语境下，他大概会带来多少收益。
--- 限于算力，我们不能编写太复杂的收益计算。默认情况下，收益可以通过推理完成，
--- 而推理的步骤需要Modder向AI给出提示。
---
--- 所谓的给出提示就是上面的“如何进行收益推理”。拓展可以针对点击某张卡牌或者
--- 点击某个角色，告诉AI这么点击了可能会发生某种事件。AI根据事件以及游戏内包含的
--- 其他技能进行计算，得出收益值。若不想让它这样计算，也可以在上一步直接指定
--- 固定的收益值。
---
--- 所谓的“可能发生某种事件”大致类似GameEvent，但是内部功能大幅简化了（因为
--- 只是用于简单的推理）。详见同文件夹下event.lua内容。
---@class SkillAI: Object
---@field public skill ActiveSkill
local SkillAI = class("SkillAI")

--- 收益估计
---@param ai SmartAI
---@return integer?
function SkillAI:getEstimatedBenefit(ai)
  return 0
end

--- 要返回一个结果，以及收益值
---@param ai SmartAI
---@return any?, integer?
function SkillAI:think(ai) end

---@param skill string
function SkillAI:initialize(skill)
  self.skill = Fk.skills[skill]
end

-- 搜索类方法：怎么走下一步？
-- choose系列的函数都是用作迭代算子的，因此它们需要能计算出所有的可选情况
-- （至少是需要所有的以及觉得可行的可选情况，如果另外写AI的话）
-- 但是也没办法一次性算出所有情况并拿去遍历。为此，只要每次调用都算出和之前不一样的解法就行了

local function cardsAcceptable(smart_ai)
  return smart_ai:okButtonEnabled() or (#smart_ai:getEnabledTargets() > 0)
end

local function cardsString(cards)
  table.sort(cards)
  return table.concat(cards, '+')
end

--- 针对一般技能的选卡搜索方案
--- 注意选真牌时面板的合法性逻辑完全不同 对真牌就没必要如此遍历了
---@param smart_ai SmartAI
function SkillAI:searchCardSelections(smart_ai)
  local searched = {}
  local function search()
    local selected = smart_ai:getSelectedCards() -- 搜索起点
    local to_remove = selected[#selected]
    -- 空情况也考虑一下
    if #selected == 0 and not searched[""] and cardsAcceptable(smart_ai) then
      return {}
    end
    -- 从所有可能的下一步找
    for _, cid in ipairs(smart_ai:getEnabledCards()) do
      table.insert(selected, cid)
      local str = cardsString(selected)
      if not searched[str] then
        smart_ai:selectCard(cid, true)
        if cardsAcceptable(smart_ai) then
          searched[str] = true
          return smart_ai:getSelectedCards()
        end
        smart_ai:selectCard(cid, false)
      end
      table.removeOne(selected, cid)
    end

    -- 返回上一步，考虑再次搜索
    if not to_remove then return nil end
    smart_ai:selectCard(to_remove, false)
    return search()
  end
  return search
end

local function targetString(targets)
  local ids = table.map(targets, Util.IdMapper)
  table.sort(ids)
  return table.concat(ids, '+')
end

---@param smart_ai SmartAI
function SkillAI:searchTargetSelections(smart_ai)
  local searched = {}
  local function search()
    local selected = smart_ai:getSelectedTargets() -- 搜索起点
    local to_remove = selected[#selected]
    -- 空情况也考虑一下
    if #selected == 0 and not searched[""] and smart_ai:okButtonEnabled() then
      searched[""] = true
      return {}
    end
    -- 从所有可能的下一步找
    for _, target in ipairs(smart_ai:getEnabledTargets()) do
      table.insert(selected, target)
      local str = targetString(selected)
      if not searched[str] then
        smart_ai:selectTarget(target, true)
        if smart_ai:okButtonEnabled() then
          searched[str] = true
          return smart_ai:getSelectedTargets()
        end
        smart_ai:selectTarget(target, false)
      end
      table.removeOne(selected, target)
    end

    -- 返回上一步，考虑再次搜索
    if not to_remove then return nil end
    smart_ai:selectTarget(to_remove, false)
    return search()
  end
  return search
end

---@param ai SmartAI
function SkillAI:chooseInteraction(ai) end

---@param ai SmartAI
function SkillAI:chooseCards(ai) end

---@param ai SmartAI
---@return any, integer?
function SkillAI:chooseTargets(ai) end

-- 流程模拟类方法：为了让AIGameLogic开心

--- 对触发技生效的模拟
---@param logic AIGameLogic
---@param event Event @ TriggerEvent
---@param target ServerPlayer @ Player who triggered this event
---@param player ServerPlayer @ Player who is operating
---@param data any @ useful data of the event
function SkillAI:onTriggerUse(logic, event, target, player, data) end

--- 对主动技生效/卡牌被使用时的模拟
---@param logic AIGameLogic
---@param event CardUseStruct | SkillEffectEvent
function SkillAI:onUse(logic, event) end

--- 对卡牌生效的模拟
---@param logic AIGameLogic
---@param cardEffectEvent CardEffectEvent | SkillEffectEvent
function SkillAI:onEffect(logic, cardEffectEvent) end

--- 最后效仿一下fk_ex故事
---@class SkillAISpec
---@field estimated_benefit? integer|fun(self: SkillAI, ai: SmartAI): integer?
---@field think? fun(self: SkillAI, ai: SmartAI): any?, integer?
---@field choose_interaction? fun(self: SkillAI, ai: SmartAI): boolean?
---@field choose_cards? fun(self: SkillAI, ai: SmartAI): boolean?
---@field choose_targets? fun(self: SkillAI, ai: SmartAI): any, integer?
---@field on_trigger_use? fun(self: SkillAI, logic: AIGameLogic, event: Event, target: ServerPlayer?, player: ServerPlayer, data: any)
---@field on_use? fun(self: SkillAI, logic: AIGameLogic, effect: SkillEffectEvent | CardEffectEvent)
---@field on_effect? fun(self: SkillAI, logic: AIGameLogic, effect: SkillEffectEvent | CardEffectEvent)

return SkillAI
