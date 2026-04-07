-- SM_Extend.lua
-- Расширенные функции для SuperMacro (WoW 1.12.1)

-- Функция для начала атаки, если она еще не идет
function StartAttack(slot_id)
  if slot_id and not IsCurrentAction(slot_id) then
    UseAction(slot_id)
  end
end

-- Функция для остановки атаки, если она идет
function StopAttack(slot_id)
  if slot_id and IsCurrentAction(slot_id) then
    UseAction(slot_id)
  end
end

-- Вспомогательная функция для применения заклинаний/предметов
function MouseOver_Spell(spellname)
  if spellname == "trinket1" then
    UseInventoryItem(13)
  elseif spellname == "trinket2" then
    UseInventoryItem(14)
  elseif spellname == "headslot" then
    UseInventoryItem(1)
  else
    CastSpellByName(spellname)
  end
end

-- Основная функция для каста на mouseover с умным таргетингом
function MouseOver(spellname)
    local hasTarget = UnitExists("target")
    local hasMouse = UnitExists("mouseover")
    local mouseIsFriend = hasMouse and UnitIsFriend("player", "mouseover")
    local targetIsMouse = hasTarget and hasMouse and UnitIsUnit("target", "mouseover")

    if hasTarget then
        if targetIsMouse then
            MouseOver_Spell(spellname)
        elseif hasMouse and not mouseIsFriend then
            TargetUnit("mouseover")
            MouseOver_Spell(spellname)
            TargetLastTarget()
        else
            MouseOver_Spell(spellname)
        end
    else
        if hasMouse and not mouseIsFriend then
            TargetUnit("mouseover")
            MouseOver_Spell(spellname)
        else
            MouseOver_Spell(spellname)
        end
    end
end

-- Функция выбора ближайшего живого врага
function MyTarget()
    if not UnitExists("target") or UnitIsFriend("player", "target") or UnitIsDead("target") then
        TargetNearestEnemy()
    end
end

-- Новая функция для вражеских целей (с проверкой на трупы и приоритетом мыши)
function MyTargetMV()
    local hasTarget = UnitExists("target")
    local needsNewTarget = false

    if not hasTarget then
        needsNewTarget = true
    elseif UnitIsFriend("player", "target") or UnitIsDead("target") then
        needsNewTarget = true
    end

    if needsNewTarget then
        if UnitExists("mouseover") and not UnitIsFriend("player", "mouseover") and not UnitIsDead("mouseover") then
            TargetUnit("mouseover")
        else
            TargetNearestEnemy()
        end
    end
end

-- Функция MyTargetMF(spellname)
-- spellname - имя заклинания (опционально). Если передано, функция проверит бафф и скастует его.
-- Логика:
-- 1. Приоритет Mouseover (дружественный): 
--    - Если под мышью друг -> проверяем бафф на нем. Если нет -> кастуем. 
--    - Временно меняем таргет на него, затем возвращаем старый.
--    - Если бафф есть -> ничего не делаем (чтобы не спамить).
-- 2. Если Mouseover нет (или он враг/труп):
--    а) Если текущий таргет дружественный и живой -> 
--       - ПРОВЕРЯЕМ БАФФ. Если баффа НЕТ -> кастуем (обновление/наложение).
--       - Если бафф ЕСТЬ -> кастуем ВСЕ РАВНО (принудительное обновление по вашему запросу).
--       - Таргет НЕ меняем.
--    б) Если таргета нет ИЛИ он враг/труп -> 
--       - Меняем таргет на себя (player).
--       - Проверяем бафф на себе. Если нет -> кастуем.

function MyTargetMF(spellname)
    local hasMouse = UnitExists("mouseover")
    local mouseIsFriend = hasMouse and UnitIsFriend("player", "mouseover")
    local mouseIsDead = hasMouse and UnitIsDead("mouseover")
    
    local hasTarget = UnitExists("target")
    local targetIsFriend = hasTarget and UnitIsFriend("player", "target")
    local targetIsDead = hasTarget and UnitIsDead("target")

    -- Сценарий 1: Есть дружественный и живой Mouseover
    if hasMouse and mouseIsFriend and not mouseIsDead then
        -- Запоминаем состояние текущего таргета, чтобы вернуть его потом
        local hadTarget = hasTarget
        
        -- Временно переключаем цель на того, кто под мышкой
        TargetUnit("mouseover")
        
        if spellname then
            -- Проверяем бафф на временной цели (mouseover)
            if not FindBuff(spellname, "mouseover") then
                CastSpellByName(spellname)
            end
            -- Если бафф есть, мы НИЧЕГО не делаем (согласно условию: "иначе бафает того кто под мышью" подразумевается только если баффа нет)
        end
        
        -- Возвращаем таргет обратно
        if hadTarget then
            TargetLastTarget()
        else
            ClearTarget()
        end
        return
    end

    -- Сценарий 2: Mouseover нет (или он не подходит). Работаем с текущим таргетом или собой.
    
    if hasTarget and targetIsFriend and not targetIsDead then
        -- Цель есть, она друг и жива. Работаем с ней, НЕ меняя таргет.
        if spellname then
            -- ЛОГИКА ОБНОВЛЕНИЯ:
            -- Если баффа нет -> кастуем.
            -- Если бафф ЕСТЬ -> кастуем ВСЕ РАВНО для обновления времени действия.
            local hasBuff = FindBuff(spellname, "target")
            
            if not hasBuff then
                CastSpellByName(spellname)
            else
                -- Бафф есть, но мы хотим его обновить (перезакастить)
                CastSpellByName(spellname)
            end
        end
        -- Таргет остался прежним. Выходим.
        return
    end
    
    -- Сценарий 3: Сюда попадаем, если:
    -- 1. Таргета нет.
    -- 2. Таргет вражеский.
    -- 3. Таргет мертвый.
    -- Действие: Переключаемся на себя.
    
    TargetUnit("player")
    
    if spellname then
        -- Проверяем бафф на себе. Если нет -> кастуем.
        -- Обычно на себя обновлять бафф без нужды не требуется, но если нужно - уберите проверку not.
        if not FindBuff(spellname, "player") then
            CastSpellByName(spellname)
        end
    end
end

--- Functions Specific to Warlocks

local function PetSpellToggle(spellname)
  local i = 1
  while true do
    local name = GetSpellName(i, BOOKTYPE_PET)
    if name == spellname then
      ToggleSpellAutocast(i, BOOKTYPE_PET)
      break
    elseif not name then
      break
    end
    i = i + 1
  end
end

function WarlockPetOff()
  local petFamily = UnitCreatureFamily('pet')
  
  if petFamily == "Felhunter" then -- Felhunter
    if IsShiftKeyDown() then
      CastSpellByName("Devour Magic")
    elseif IsControlKeyDown() then
      TargetUnit("pet") 
      CastSpellByName("Devour Magic") 
      TargetLastTarget()
    else
      MouseOver("Spell Lock")
    end
  elseif petFamily == "Succubus" then -- Succubus
    if IsShiftKeyDown() then
      PetSpellToggle("Seduction")
    elseif IsControlKeyDown() then
      PetSpellToggle("Lash of Pain")
    elseif IsAltKeyDown() then
      PetSpellToggle("Soothing Kiss")
    else
      MouseOver("Seduction")
    end
  elseif petFamily == "Voidwalker" then -- Voidwalker
    if IsControlKeyDown() then
      PetSpellToggle("Consume Shadows")
    elseif IsAltKeyDown() then
      PetSpellToggle("Torment")
    else 
      CastSpellByName("Sacrifice")
    end
  elseif petFamily == "Imp" then -- Imp
    if UnitExists("mouseover") then 
      TargetUnit("mouseover") 
      CastSpellByName("Fire Shield")
      TargetLastTarget()
    elseif UnitExists("target") and UnitIsFriend("player", "target") then 
      CastSpellByName("Fire Shield")
    elseif UnitExists("target") and not UnitIsFriend("player", "target") then 
      TargetUnit("targettarget") 
      CastSpellByName("Fire Shield") 
      TargetLastTarget()
    elseif not UnitExists("target") then 
      CastSpellByName("Fire Shield", 1)
    end
  end
end

function WarlockPetDef()
  local petFamily = UnitCreatureFamily('pet')

  if petFamily == "Felhunter" then -- Felhunter
    CastSpellByName("Devour Magic", 1)
  elseif petFamily == "Succubus" then -- Succubus
    PetSpellToggle("Lesser Invisibility")
  elseif petFamily == "Voidwalker" then -- Voidwalker
    CastSpellByName("Suffering") -- mass taunt
  elseif petFamily == "Imp" then -- Imp
    PetSpellToggle("Firebolt")
    PetSpellToggle("Fire Shield")
  end
end


--- Functions Specific to Hunters

function fdTrap(trapName)
  local c = CastSpellByName
  c(trapName)
  if UnitAffectingCombat("player") then
    c("Feign Death")
  end
  if UnitExists("pettarget") and CheckInteractDistance("target", 3) and UnitIsUnit("target", "pettarget") then 
    PetPassiveMode()
  end
end