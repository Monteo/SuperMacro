
local function GetAddonDir()
    local name = "SuperMacro"
    for i=1, GetNumAddOns() do
        name = GetAddOnInfo(i)
        if string.find(name, "SuperMacro") then
            break
        end
    end
    return "Interface\\AddOns\\"..name
end


local function AddCustomHandlerForEditBox(editBox)
    -- Add tabulation handler
    editBox:SetScript("OnTabPressed", function()
        this:Insert("  ")
    end)

    local scrollFrame = editBox:GetParent()

    -- Add line show
    editBox.textLineNumber = scrollFrame:CreateFontString("Status", "LOW", "GameFontHighlightSmall")
    editBox.textLineNumber:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -50, -16)
    editBox.textLineNumber:SetJustifyH("LEFT")

    editBox:SetScript("OnCursorChanged", function()
        local x = arg1
        local y = arg2
        local lineHeight = arg4
        local lineNumber = math.abs(math.floor(y / lineHeight + 0.5)) + 1
    this.textLineNumber:SetText(string.format("Line: %4d", lineNumber))
    end)
end

-- Post load initialization for SuperMacro frames
function SuperMacroInitFrames()
    SuperMacroUpdateConfig()
    AddCustomHandlerForEditBox(SuperMacroFrameText)
    AddCustomHandlerForEditBox(SuperMacroFrameExtendText)
    AddCustomHandlerForEditBox(SuperMacroFrameSuperText)
end

function SuperMacroHandleEditBox(editBox)
    local scrollBar = getglobal(editBox:GetParent():GetName().."ScrollBar")
    editBox:GetParent():UpdateScrollChildRect();

    local _, max = scrollBar:GetMinMaxValues();
    scrollBar.prevMaxValue = scrollBar.prevMaxValue or max

    if math.abs(scrollBar.prevMaxValue - scrollBar:GetValue()) <= 1 then
        -- if scroll is down and add new line then move scroll
        scrollBar:SetValue(max);
    end
    if max ~= scrollBar.prevMaxValue then
        -- save max value
        scrollBar.prevMaxValue = max
    end
end

function SuperMacroUpdateConfig()
    local windowSizeXMin = 590
    local windowSizeYMin = 512
    local windowSizeXMax = math.floor(UIParent:GetRight())
    local windowSizeYMax = math.floor(UIParent:GetTop())

    SM_VARS.windowWidth = math.max(SM_VARS.windowWidth, windowSizeXMin)
    SM_VARS.windowWidth = math.min(SM_VARS.windowWidth, windowSizeXMax)

    SM_VARS.windowHeight = math.max(SM_VARS.windowHeight, windowSizeYMin)
    SM_VARS.windowHeight = math.min(SM_VARS.windowHeight, windowSizeYMax)

    local editBoxFont = "Fonts\\FRIZQT__.TTF"
    if SM_VARS.monoFont == 1 then
        editBoxFont = GetAddonDir().."\\fonts\\UbuntuMono-R.ttf"
    end
    local textFontSize = SM_VARS.editBoxFontSize or 10

    local sizeX = SM_VARS.windowWidth
    local sizeY = SM_VARS.windowHeight

    local scrollFrameSizeX = math.min((sizeX - 145) / 2 + 15, 500)
    local scrollFrameSizeY = sizeY - 413

    local extendScrollFrameSizeX = sizeX - scrollFrameSizeX - 130
    local extendScrollFrameSizeY = scrollFrameSizeY + 40
    if sizeX > 1110 then
        extendScrollFrameSizeY = scrollFrameSizeY + 220
    end

    local superEditScrollFrameSizeX = sizeX - 92
    local superEditScrollFrameSizeY = scrollFrameSizeY

    -- Main Frame
    SuperMacroFrame:SetWidth(sizeX)
    SuperMacroFrame:SetHeight(sizeY)

    -- interface
    SuperMacroFrameMainBackground:SetWidth(sizeX - windowSizeXMin + 546)
    SuperMacroFrameMainBackground:SetHeight(sizeY - windowSizeYMin + 430)

    -- SuperMacroFrame
    SuperMacroFrameScrollFrame:SetWidth(scrollFrameSizeX)
    SuperMacroFrameScrollFrame:SetHeight(scrollFrameSizeY)

    SuperMacroFrameTextBackground:SetWidth(scrollFrameSizeX + 36)
    SuperMacroFrameTextBackground:SetHeight(scrollFrameSizeY + 12)

    SuperMacroFrameText:SetWidth(scrollFrameSizeX - 2)
    SuperMacroFrameText:SetHeight(scrollFrameSizeY)
    SuperMacroFrameText:SetFont(editBoxFont, textFontSize)


    -- SuperMacroFrameExtend
    SuperMacroFrameExtendScrollFrame:SetWidth(extendScrollFrameSizeX)
    SuperMacroFrameExtendScrollFrame:SetHeight(extendScrollFrameSizeY)

    SuperMacroFrameExtendTextBackground:SetWidth(extendScrollFrameSizeX + 36)
    SuperMacroFrameExtendTextBackground:SetHeight(extendScrollFrameSizeY + 12)

    SuperMacroFrameExtendText:SetWidth(extendScrollFrameSizeX - 4)
    SuperMacroFrameExtendText:SetHeight(extendScrollFrameSizeY)
    SuperMacroFrameExtendText:SetFont(editBoxFont, textFontSize)

    -- SuperMacroFrameSuper
    SuperMacroFrameSuperEditScrollFrame:SetWidth(superEditScrollFrameSizeX)
    SuperMacroFrameSuperEditScrollFrame:SetHeight(superEditScrollFrameSizeY)

    SuperMacroFrameSuperTextBackground:SetWidth(superEditScrollFrameSizeX + 36)
    SuperMacroFrameSuperTextBackground:SetHeight(superEditScrollFrameSizeY + 12)

    SuperMacroFrameSuperText:SetWidth(superEditScrollFrameSizeX - 1)
    SuperMacroFrameSuperText:SetHeight(superEditScrollFrameSizeY)
    SuperMacroFrameSuperText:SetFont(editBoxFont, textFontSize)
end

