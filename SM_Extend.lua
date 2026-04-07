function StartAttack(slot_id)
  if not IsCurrentAction(slot_id) then
    UseAction(slot_id)
  end
end

function StopAttack(slot_id)
  if IsCurrentAction(slot_id) then
    UseAction(slot_id)
  end
end

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

function MouseOver(spellname)
    if UnitExists("target") then
    if UnitExists("mouseover") and UnitIsUnit("target","mouseover") then
      MouseOver_Spell(spellname)
    elseif UnitExists("mouseover") and not UnitIsFriend("player", "mouseover") then
      TargetUnit("mouseover"); MouseOver_Spell(spellname); TargetLastTarget()
     else
      MouseOver_Spell(spellname)
     end
  else
    if UnitExists("mouseover") and not UnitIsFriend("player", "mouseover") then
      TargetUnit("mouseover"); MouseOver_Spell(spellname)
    else
      MouseOver_Spell(spellname)
    end
  end
end

function MyTarget()
	if GetUnitName("target")==nil or UnitIsFriend ("player", "target") or UnitIsDead("target") then TargetNearestEnemy() end
end

function MyTargetMV()
	if GetUnitName("target")==nil or UnitIsFriend ("player", "target") or UnitIsDead("target") then 
		if UnitExists("mouseover") and not UnitIsFriend("player", "mouseover") then 
			TargetUnit("mouseover") 
		else 
			TargetNearestEnemy() 
		end 
	end
end

---functions Specific to Warlocks

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
  if UnitCreatureFamily('pet') == "Felhunter" then --Felhunter
    if IsShiftKeyDown() then
      CastSpellByName("Devour Magic")
    elseif IsControlKeyDown() then
      TargetUnit("pet"); CastSpellByName("DevourMagic"); TargetLastTarget()
    else
      MouseOver("Spell Lock")
    end
  elseif UnitCreatureFamily('pet') == "Succubus" then --Succubus
    if IsShiftKeyDown() then
      PetSpellToggle("Seduction")
    elseif IsControlKeyDown() then
      PetSpellToggle("Lash of Pain")
    elseif IsAltKeyDown() then
      PetSpellToggle("Soothing Kiss")
    else
      MouseOver("Seduction")
    end
  elseif UnitCreatureFamily('pet') == "Voidwalker" then --Voidwalker
    if IsControlKeyDown() then
		PetSpellToggle("Consume Shadows")
	elseif IsAltKeyDown() then
      PetSpellToggle("Torment")
	else 
		CastSpellByName("Sacrifice")
	end
  elseif UnitCreatureFamily('pet') == "Imp" then --Imp
   if UnitExists("mouseover") then 
		TargetUnit("mouseover"); 
	    CastSpellByName("Fire Shield"); 
		TargetUnit("playertarget");
	elseif UnitExists("target") and UnitIsFriend ("player", "target") then 
		CastSpellByName("Fire Shield")
	elseif UnitExists("target") and not UnitIsFriend ("player", "target") then 
		TargetUnit("targettarget"); 
		CastSpellByName("Fire Shield"); 
		TargetLastTarget()
	elseif GetUnitName("target")==nil then 
		CastSpellByName("Fire Shield",1)
    end
  end
end

function WarlockPetDef()
  if UnitCreatureFamily('pet') == "Felhunter" then --Felhunter
    CastSpellByName("Devour Magic",1)
  elseif UnitCreatureFamily('pet') == "Succubus" then --Succubus
    PetSpellToggle("Lesser Invisibility")
  elseif UnitCreatureFamily('pet') == "Voidwalker" then --Voidwalker
    CastSpellByName("Suffering") --mass taunt
  elseif UnitCreatureFamily('pet') == "Imp" then --Imp
    PetSpellToggle("Firebolt")
	PetSpellToggle("Fire Shield")
	end
end


---functions Specific to Hunters

function fdTrap(trapName)
	local c=CastSpellByName
	c(trapName)
	if UnitAffectingCombat("player") then
		c("Feign Death")
	end
	if UnitExists("pettarget") and CheckInteractDistance("target", 3) and UnitIsUnit("target", "pettarget") then 
		PetPassiveMode()
	end
end
