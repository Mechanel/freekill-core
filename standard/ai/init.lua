if UsingNewCore then
  require "standard.ai.aux_skills"
else
  require "packages.standard.ai.aux_skills"
end

SmartAI:setSkillAI("jianxiong", {
  think_skill_invoke = function(self, ai, skill_name, prompt)
    ---@type DamageStruct
    local dmg = ai.room.logic:getCurrentEvent().data[1]
    local player = ai.player
    local card = dmg.card
    if not card or player.room:getCardArea(card) ~= Card.Processing then return false end
    local val = ai:getBenefitOfEvents(function(logic)
      logic:obtainCard(player, card, true, fk.ReasonJustMove)
    end)
    if val > 0 then
      return true
    end
    return false
  end,
})

SmartAI:setSkillAI("ganglie", {
  think = function(self, ai)
    local cards = ai:getEnabledCards()
    if #cards < 2 then return "" end
    local to_discard = table.random(cards, 2) -- TODO: 用于选择最适合弃牌的ai函数
    local cancel_val = ai:getBenefitOfEvents(function(logic)
      logic:damage{
        from = ai.room.logic:getCurrentEvent().data[2],
        to = ai.player,
        damage = 1,
        skillName = self.skill.name,
      }
    end)
    local discard_val = ai:getBenefitOfEvents(function(logic)
      logic:throwCard(to_discard, self.skill.name, ai.player, ai.player)
    end)

    if discard_val > cancel_val then
      return { cards = to_discard }
    else
      return ""
    end
  end,

  think_skill_invoke = function(self, ai, skill_name, prompt)
    ---@type DamageStruct
    local dmg = ai.room.logic:getCurrentEvent().data[1]
    local from = dmg.from
    if not from then return false end
    local dmg_val = ai:getBenefitOfEvents(function(logic)
      logic:damage{
        from = ai.player,
        to = from,
        damage = 1,
        skillName = self.skill.name,
      }
    end)
    local discard_val = ai:getBenefitOfEvents(function(logic)
      local cards = from:getCardIds("h")
      if #cards < 2 then
        logic.benefit = -1
        return
      end
      logic:throwCard(table.random(cards, 2), self.skill.name, from, from)
    end)
    if dmg_val > 0 or discard_val > 0 then
      return true
    end
    return false
  end,
})

SmartAI:setSkillAI("fankui", {
  think_skill_invoke = function(self, ai, skill_name, prompt)
    ---@type DamageStruct
    local dmg = ai.room.logic:getCurrentEvent().data[1]
    local player = ai.player
    local from = dmg.from
    if not from then return false end
    local val = ai:getBenefitOfEvents(function(logic)
      local flag = from == player and "e" or "he"
      local cards = from:getCardIds(flag)
      if #cards < 1 then
        logic.benefit = -1
        return
      end
      logic:obtainCard(player, cards[1], false, fk.ReasonPrey)
    end)
    if val > 0 then
      return true
    end
    return false
  end,
})

SmartAI:setSkillAI("tuxi", {
  think = function(self, ai)
    local player = ai.player
    -- 选出界面上所有可选的目标
    local players = ai:getEnabledTargets()
    -- 对所有目标计算他们被拿走一张手牌后对自己的收益
    local benefits = table.map(players, function(p)
      return { p, ai:getBenefitOfEvents(function(logic)
        local c = p:getCardIds("h")[1]
        logic:obtainCard(player.id, c, false, fk.ReasonPrey)
      end)}
    end)
    -- 选择收益最高且大于0的两位 判断偷两位的收益加上放弃摸牌的负收益是否可以补偿
    local total_benefit = -ai:getBenefitOfEvents(function(logic)
      logic:drawCards(player, 2, self.skill.name)
    end)
    local targets = {}
    table.sort(benefits, function(a, b) return a[2] > b[2] end)
    for i, benefit in ipairs(benefits) do
      local p, val = table.unpack(benefit)
      if val < 0 then break end
      table.insert(targets, p)
      total_benefit = total_benefit + val
      if i == 2 then break end
    end
    if #targets == 0 or total_benefit <= 0 then return "" end
    return { targets = targets }, total_benefit
  end,
})

SmartAI:setTriggerSkillAI("#kongchengAudio", {
  correct_func = function(self, logic, event, target, player, data)
    if self.skill:canRefresh(event, target, player, data) then
      logic.benefit = logic.benefit + 350
    end
  end,
})

SmartAI:setSkillAI("jizhi", {
  think_skill_invoke = function(self, ai, skill_name, prompt)
    return ai:getBenefitOfEvents(function(logic)
      logic:drawCards(ai.player, 1, self.skill.name)
    end) > 0
  end,
})

SmartAI:setSkillAI("zhiheng", {
  think = function(self, ai)
    local player = ai.player
    local cards = ai:getEnabledCards()
    return { cards = cards }, ai:getBenefitOfEvents(function(logic)
      logic:throwCard(cards, self.skill.name, player, player)
      logic:drawCards(player, #cards, self.skill.name)
    end)
  end,
})

SmartAI:setTriggerSkillAI("jiuyuan", {
  correct_func = function(self, logic, event, target, player, data)
    if self.skill:triggerable(event, target, player, data) then
      data.num = data.num + 1
    end
  end,
})

SmartAI:setSkillAI("keji", {
  think_skill_invoke = Util.TrueFunc,
})

SmartAI:setSkillAI("lianying", nil, "jizhi")
SmartAI:setTriggerSkillAI("lianying", {
  correct_func = function(self, logic, event, target, player, data)
    if self.skill:triggerable(event, target, player, data) then
      logic:drawCards(logic.player, 1, self.skill.name)
    end
  end,
})

SmartAI:setSkillAI("yingzi", {
  think_skill_invoke = Util.TrueFunc,
})

SmartAI:setSkillAI("xiaoji", {
  think_skill_invoke = function(self, ai, skill_name, prompt)
    return ai:getBenefitOfEvents(function(logic)
      logic:drawCards(ai.player, 2, self.skill.name)
    end) > 0
  end,
})

SmartAI:setSkillAI("biyue", nil, "jizhi")

SmartAI:setSkillAI("wusheng", nil, "spear_skill")

SmartAI:setSkillAI("longdan", nil, "spear_skill")

SmartAI:setSkillAI("guose", nil, "spear_skill")

SmartAI:setSkillAI("jijiu", nil, "spear_skill")

SmartAI:setSkillAI("qixi", nil, "spear_skill")