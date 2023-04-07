-- SuperMacroExtend handlers

-- string: saved current extend script page to show.
local currentPageId


-- Change current page to new Id
local function SetCurrentPage(pageId)
    currentPageId = pageId
    local extendText
    if currentPageId then
        extendText=SM_EXTEND[currentPageId]
    end
    if extendText then
        SuperMacroFrameExtendText:SetText(extendText)
    else
        -- Create new or invalid id. Show empty text
        SuperMacroFrameExtendText:SetText("")
    end
end

-- Save current extend script text to SM_EXTEND and update UI
local function SaveCurrentPage()
    if not currentPageId then
        return
    end

    local text=SuperMacroFrameExtendText:GetText()
    if text and text~="" then
        SM_EXTEND[currentPageId]=text
    else
        -- auto delete empty page
        SM_EXTEND[currentPageId]=nil
    end

    SuperMacroFrameExtendText:ClearFocus()
    SuperMacroSaveExtendButton:SetTextColor(0.5, 0.5, 0.5)
end

-- Run all current scripts
local function RunAllScripts()
    for m,e in pairs(SM_EXTEND) do
        if ( e ) then
            RunScript(e)
        end
    end
end




-- External functions
-- Initialize extend macro
function SuperMacroInitExtend()
    RunAllScripts()
end

-- Save current UI text changes and run scripts
function SuperMacroRunAllExtend()
    SaveCurrentPage()
	RunAllScripts()
end

function SuperMacroSelectExtend(pageId)
    SaveCurrentPage()
    SetCurrentPage(pageId)
end

function SuperMacroCopyExtend(fromId, toId)
    assert(fromId ~= toId)
    SaveCurrentPage()

    local text = SM_EXTEND[fromId]
    SM_EXTEND[toId] = text
end

function SuperMacroDeleteExtend(pageId)
    SaveCurrentPage()
    SM_EXTEND[pageId]=nil
    if pageId == currentPageId then
        -- Update script UI
        SetCurrentPage(pageId)
    end
end

-- Save button action
function SuperMacroSaveExtendButton_OnClick()
    SuperMacroRunAllExtend()
end

-- Delete button action
function SuperMacroDeleteExtendButton_OnClick()
    if currentPageId then
        SuperMacroDeleteExtend(currentPageId)
    end
    SuperMacroRunAllExtend()
end

-- UI change text action
function SuperMacroFrameExtendText_OnTextChanged()
    SuperMacroFrameExtendCharLimitText:SetText(format(TEXT(SUPERMACROFRAME_EXTEND_CHAR_LIMIT), strlen(SuperMacroFrameExtendText:GetText())))
    SuperMacroHandleEditBox(SuperMacroFrameExtendText)
    SuperMacroSaveExtendButton:SetTextColor(1, 0.82, 0)
end

function SuperMacroSetDefaultTooltipColor(frame)
    frame:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
    frame:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
end
