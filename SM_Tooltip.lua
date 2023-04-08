--SM_VARS.macroTip1 = 1; -- for spell, item
--SM_VARS.macroTip2 = 1; -- for macro code

SM_ITEM_PATTERN = "[%w '%-:]+";
SM_SPELL_PATTERN="[%w'%(%) %-:]+";

oldActionButton_SetTooltip=ActionButton_SetTooltip;
function ActionButton_SetTooltip()
	oldActionButton_SetTooltip();
	local actionid=ActionButton_GetPagedID(this);
	SM_ActionButton_SetTooltip(actionid);
end
--fix Error: attempt to index a nil value in function 'ActionButton_GetPagedID'  [Monteo]
oldBActionButton_SetTooltip=BActionButton_SetTooltip;
function BActionButton_SetTooltip()
	oldBActionButton_SetTooltip();
	local actionid=BActionButton.GetPagedID(this:GetID());
	SM_ActionButton_SetTooltip(actionid);
end

-- Hooking into tooltip caller of Bongos [Fixed by Threewords]
if (BActionButton ~= nil) then
	oldUpdateTooltip=BActionButton.UpdateTooltip;
	BActionButton.UpdateTooltip = function(button)
		oldUpdateTooltip(button);
		local actionid=BActionButton.GetPagedID(this:GetID());
		SM_ActionButton_SetTooltip(actionid);
	end
end

if (DAB_ActionButton_OnEnter ~= nil) then
	oldDAB_ActionButton_OnEnter=DAB_ActionButton_OnEnter;
	DAB_ActionButton_OnEnter = function()
		oldDAB_ActionButton_OnEnter();
		local actionid = this:GetActionID();
		SM_ActionButton_SetTooltip(actionid);
	end
end

function SM_ActionButton_SetTooltip(actionid)
	--local actionid=ActionButton_GetPagedID(this);
	local macroname=GetActionText(actionid); --or getglobal(this:GetName().."Name"):GetText();
	if ( macroname ) then
		local macro, _, body = GetMacroInfo(GetMacroIndexByName(macroname));
		
		-- for supermacros
		local superfound = SM_ACTION[actionid];
		if ( superfound ) then
			macro,_,body=GetSuperMacroInfo(superfound);
			GameTooltipTextLeft1:SetText(macro);
			GameTooltip:Show();
		end

		if ( SM_VARS.macroTip1==1 ) then
			local actiontype, spell = SM_GetActionSpell(macro, superfound);
			if ( actiontype=="spell" ) then
				local id, book = SM_FindSpell(spell);
				GameTooltip:SetSpell(id, book);
			if TheoryCraft_AddTooltipInfo then
				TheoryCraft_AddTooltipInfo(GameTooltip)
			else	
				local s, r = GetSpellName(id, book);
				if ( r ) then
					GameTooltipTextRight1:SetText("|cff00ffff"..r.."|r");
					GameTooltipTextRight1:Show();
					GameTooltip:Show();
				end
			end
				return;
			elseif ( actiontype=="item" ) then
				local id, book = FindItem(spell);
				if ( book ) then
					GameTooltip:SetBagItem(id, book);
				elseif ( id ) then
					GameTooltip:SetInventoryItem( 'player', id);
				end
				return;
			end
		end
		if ( SM_VARS.macroTip2 == 1 ) then
			-- show macro code
			if ( not GameTooltipTextLeft1:GetText() ) then return; end
			body = gsub(body, "\n$", "");
			GameTooltipTextLeft1:SetText( "|cff00ffff"..macro.."|r");
			GameTooltipTextLeft2:SetText("|cffffffff"..body.."|r");
			GameTooltipTextLeft2:Show();
			GameTooltipTextLeft1:SetWidth(284);
			GameTooltipTextLeft2:SetWidth(284);
			GameTooltip:SetWidth(300);
			GameTooltip:SetHeight( GameTooltipTextLeft1:GetHeight() + GameTooltipTextLeft2:GetHeight() + 23);
			GameTooltipTextLeft2:SetNonSpaceWrap(true);
			return;
		end
	end
	-- brighten rank text on all tooltips
	if ( GameTooltipTextRight1:GetText() ) then
		local t = GameTooltipTextRight1:GetText();
		GameTooltipTextRight1:SetText("|cff00ffff"..t.."|r");
	end
	-- show crit info for Attack
	if ( GameTooltipTextLeft1:GetText()=="Attack" ) then
		id, book = FindSpell("Attack","");
		GameTooltip:SetSpell(id, book);
		GameTooltip:Show();
	end
end

function SM_ActionButton_OnLeave()
	this.updateTooltip=nil;
	GameTooltipTextLeft2:SetWidth(100);
	GameTooltipTextLeft2:SetText("");
	GameTooltip:Hide();
end

local oldGetActionCooldown = GetActionCooldown;
function GetActionCooldown( actionid )
	-- start, duration, enable
	local macro=GetActionText(actionid);
	if ( macro and SM_VARS.checkCooldown==1 ) then
		local name, icon, body = GetMacroInfo(GetMacroIndexByName(macro));
		--  for supermacros
		local superfound = SM_ACTION[actionid];
		if ( superfound ) then
			name,icon,body=GetSuperMacroInfo(superfound);
		end

		local buttonName = this:GetName() or ("BActionButton"..actionid);	-- The part after 'or' is to support Bongos [Fixed by Threewords]

		local macroname, pic;
		if ( this ) then
			macroname=getglobal(buttonName.."Name");
			if ( macroname ) then
				macroname:SetText(name);
			end
			pic = getglobal(buttonName.."Icon");
			if ( pic ) then
				pic:SetTexture(icon);
			end
		end

		local actiontype, spell, texture = SM_GetActionSpell(name, superfound);
		if ( actiontype=="spell") then
			if ( SM_VARS.replaceIcon==1 and texture and pic) then
				pic:SetTexture(texture);
			end
			local id, book = SM_FindSpell(spell);
			return GetSpellCooldown( id, book);
		elseif ( actiontype=="item") then
			if ( SM_VARS.replaceIcon==1 and texture and pic) then
				pic:SetTexture(texture);
			end
			local id, book, texture, count = FindItem(spell);
			if ( count and count>1 and macroname ) then
				macroname:Hide();
				getglobal(buttonName.."Count"):SetText(count);
			elseif ( macroname ) then
				macroname:Show();
				getglobal(buttonName.."Count"):SetText("");
			end
			if ( book ) then
				return GetContainerItemCooldown(id, book);
			elseif ( id ) then
				return GetInventoryItemCooldown('player', id);
			end
		end
	end
	return oldGetActionCooldown( actionid );
end

function FindFirstSpell( text )
	if not text then return nil end;
	local body = text;
	if (ReplaceAlias and ASFOptions.aliasOn) then
		-- correct aliases
		body = ReplaceAlias(body);
	end
	local id, book, texture, spell;
	while ( string.find(body, "CastSpellByName") ) do
		spell = gsub(body,'^.-CastSpellByName.-%(.-(["\'])(.-)%1.*$','%2');
		id, book = SM_FindSpell(spell);
		if ( id ) then
			texture = GetSpellTexture(id, book);
			break;
		end
		body = gsub(body, "CastSpellByName","",1);
	end
	if ( not id and string.find(body,"/cast") ) then
			spell = gsub(body,'^.-/cast *('..SM_SPELL_PATTERN..')[\n]?.*$','%1');
			id, book = SM_FindSpell(spell);
			if ( id and book ) then
				texture = GetSpellTexture(id, book);
			end
	end
	if ( not id ) then
		while ( string.find(body, "[%p%s]cast%(") ) do
			spell = gsub(body,'^.-[%p%s]-cast%(.-(["\'])(.-)%1.*$','%2');
			id, book = SM_FindSpell(spell);
			if ( id ) then
				texture = GetSpellTexture(id, book);
				break;
			end
			body = gsub(body, "[%p%s]cast%(","", 1);
		end
	end
	if ( not id ) then
		while ( string.find(body, "CastSpell")) do
			spell = gsub(body,'^.-CastSpell.-%(%s*(.-)%s*)%s*%).*$','%1');
			local _,_,spellid = strfind(spell,"^(%d+).*");
			if ( spellid ) then
				local _,_,spellbook=strfind(spell,"^.-"..spellid..",%s*'(%a+)'%s*");
				id=spellid;
				book=spellbook or 'spell';
				texture = GetSpellTexture(id, book);
				break;
			end
			body = gsub(body, "CastSpell","", 1);
		end
	end
	return id, book, texture, spell;
end

function FindFirstItem( text )
	if not text then return nil end;
	local body = text;
	if (ReplaceAlias and ASFOptions.aliasOn) then
		-- correct aliases
		body = ReplaceAlias(body);
	end
	local bag, slot, texture, count, item;
	if ( strfind(body,"UseItemByName") ) then
		while ( string.find(body, "UseItemByName") ) do
			item = gsub(body,'^.-UseItemByName.-%(.-(["\'])(.-)%1.*$','%2');
			bag, slot, texture, count = FindItem(item);
			if ( bag ) then
				return bag, slot, texture, count, item;
			end
			body = gsub(body, "UseItemByName","", 1);
		end
	end
	if ( strfind(body,"/use") ) then
		while ( string.find(body, "/use") ) do
			if ( strfind(body, '^.-/use *%d') ) then
				-- number means container or inventory slot
				bag, slot = nil, nil;
				gsub(body,'^.-/use -(%d+)[,%s]*(%d*)', function(b,s)
					bag=tonumber(b);
					slot=tonumber(s);
				end );
				if ( bag and slot ) then
					texture, count = GetContainerItemInfo(bag, slot);
					item = ItemLinkToName(GetContainerItemLink(bag, slot));
				elseif ( bag and bag>0 and bag<=23) then
					texture, count = GetInventoryItemTexture('player', bag), GetInventoryItemCount('player', bag);
					item = ItemLinkToName(GetInventoryItemLink('player', bag));
				end
			else
				-- not a number
				item = gsub(body,'^.-/use *('..SM_ITEM_PATTERN..')\n?.*$', '%1');
				bag, slot, texture, count = FindItem(item);
			end
			if ( bag ) then
				return bag, slot, texture, count, item;
			end
			body = gsub(body, "/use","", 1);
		end
	end
	if ( strfind(body,"use") ) then
		while ( string.find(body, "use") ) do
			if ( strfind(body, '^.-use.-%(%s*%d') ) then
				-- number means container or inventory slot
				bag, slot = nil, nil;
				gsub(body,'^.-use.-%(.-(%d+)[,%s]*(%d*)', function(b,s)
					bag=tonumber(b);
					slot=tonumber(s);
				end );
				if ( bag and slot ) then
					texture, count = GetContainerItemInfo(bag, slot);
					item = ItemLinkToName(GetContainerItemLink(bag, slot));
				elseif ( bag and bag>0 and bag<=23) then
					texture, count = GetInventoryItemTexture('player', bag), GetInventoryItemCount('player', bag);
					item = ItemLinkToName(GetInventoryItemLink('player', bag));
				end
			else
				-- not a number
				item = gsub(body,'^.-use.-%(.-(["\'])('..SM_ITEM_PATTERN..')%1.*$','%2');
				bag, slot, texture, count = FindItem(item);
			end
			if ( bag ) then
				return bag, slot, texture, count, item;
			end
			body = gsub(body, "use","", 1);
		end
	end
	while ( strfind(body, "UseInventoryItem") ) do
		bag = gsub(body,'^.-UseInventoryItem.-(%d+)%s-%).*$','%1');
		if ( bag~=body) then
			texture = GetInventoryItemTexture('player', bag);
			count = GetInventoryItemCount('player', bag);
		end
		if ( texture ) then
			item=ItemLinkToName( GetInventoryItemLink('player', bag) );
			return bag, slot, texture, count, item;
		end
		body = gsub(body, "UseInventoryItem","", 1);
	end
	while ( strfind(body, "UseContainerItem") ) do
		bag = gsub(body,'^.-UseContainerItem.-(%d+)%s-,%s-(%d+)%s-%).*$','%1');
		slot = gsub(body,'^.-UseContainerItem.-(%d+)%s-,%s-(%d+)%s-%).*$','%2');
		if ( bag~=body and slot~=body) then
			texture, count = GetContainerItemInfo(bag, slot);
		end
		if ( bag~=body and slot~=body and texture ) then
			item=ItemLinkToName( GetContainerItemLink(bag, slot) );
			return bag, slot, texture, count, item;
		end
		body = gsub(body, "UseContainerItem","", 1);
	end
end
