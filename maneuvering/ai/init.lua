SmartAI:setCardSkillAI("thunder__slash_skill", nil, "slash_skill")
SmartAI:setCardSkillAI("fire__slash_skill", nil, "slash_skill")

SmartAI:setCardSkillAI("iron_chain_skill", {
  on_effect = function(self, logic, effect)
    local target = logic:getPlayerById(effect.to)
    logic:setPlayerProperty(target, "chained", not target.chained)
  end,
})

SmartAI:setCardSkillAI("fire_attack_skill", {
  on_effect = function(self, logic, effect)
    local from = logic:getPlayerById(effect.from)
    local to = logic:getPlayerById(effect.to)
    if to:isKongcheng() then return end
    if from:isKongcheng() then return end
    logic:throwCard(from.player_cards[Player.Hand][1], self.skill.name, from)
    logic:damage({
      from = from,
      to = to,
      card = effect.card,
      damage = 1,
      damageType = fk.FireDamage,
      skillName = self.skill.name
    })
  end,
})

SmartAI:setCardSkillAI("supply_shortage_skill")

--[[
SmartAI:setSkillAI("analeptic_skill", just_use)
--]]

SmartAI:setTriggerSkillAI("#guding_blade_skill", {
  correct_func = function(self, logic, event, target, player, data)
    if self.skill:triggerable(event, target, player, data) then
      data.damage = data.damage + 1
    end
  end,
})

SmartAI:setTriggerSkillAI("#vine_skill", {
  correct_func = function(self, logic, event, target, player, data)
    local skill = self.skill
    if skill:triggerable(event, target, player, data) then
      if event == fk.DamageInflicted then
        data.damage = data.damage + 1
      else
        return true
      end
    end
  end,
})
