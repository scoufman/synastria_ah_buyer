local AUCTION_LIST = "list"
local ROW_BUTTON_WIDTH = 30
local ROW_BUTTON_HEIGHT = 16
local ROW_BUTTON_GAP = 2
local ROW_BUTTON_FONT_SIZE = 9
local PRICE_FRAME_OFFSET = 9
local BROWSE_RESULT_FONT_SIZE = 10
local PRICE_FONT_SIZE = 13
local MONEY_ICON_WIDTH = 13
local MONEY_DENOMINATIONS = {
    { name = "Gold" },
    { name = "Silver", minimumText = "00" },
    { name = "Copper", minimumText = "00" },
}

local LEVEL_COLUMN_REDUCTION = 22
local LEVEL_COLUMN_OVERLAP = 5
local BROWSE_RESULT_FONT_FIELDS = {
    "Name",
    "Level",
    "ClosingTimeText",
    "HighBidder",
}
local ROW_ACTIONS = {
    buyout = {
        title = "Instant Buyout",
        enabled = "Click to buy this auction immediately.",
        disabled = "This auction cannot currently be bought.",
    },
    bid = {
        title = "Minimum Bid",
        enabled = "Click to place the minimum allowed bid.",
        disabled = "You cannot currently bid on this auction.",
    },
}

local eventFrame = CreateFrame("Frame")
local rowBuyoutButtons = {}
local rowBidButtons = {}
local rowWidgets = {}

local function ShowError(message)
    UIErrorsFrame:AddMessage(message, 1, 0.1, 0.1)
end

local function SetEnabled(button, enabled)
    if enabled then
        button:Enable()
    else
        button:Disable()
    end
end

local function SetFontSize(fontString, fontSize)
    if not fontString then
        return
    end

    local fontFile, _, fontFlags = fontString:GetFont()
    if fontFile then
        fontString:SetFont(fontFile, fontSize, fontFlags)
    end
end

local function PrepareMoneyFrame(frameName)
    local frame = _G[frameName]
    if not frame then
        return nil
    end

    local denominations = {}
    for _, denomination in ipairs(MONEY_DENOMINATIONS) do
        local buttonName = frameName .. denomination.name .. "Button"
        local button = _G[buttonName]
        if button then
            local fontString = button:GetFontString() or _G[buttonName .. "Text"]
            if fontString then
                SetFontSize(fontString, PRICE_FONT_SIZE)

                if fontString.SetJustifyH then
                    fontString:SetJustifyH("RIGHT")
                end

                local minimumWidth = 0
                if denomination.minimumText then
                    local text = fontString:GetText()
                    fontString:SetText(denomination.minimumText)
                    minimumWidth = fontString:GetStringWidth()
                    fontString:SetText(text or "")
                end

                denominations[#denominations + 1] = {
                    button = button,
                    fontString = fontString,
                    minimumWidth = minimumWidth,
                }
            end
        end
    end

    return { frame = frame, denominations = denominations }
end

local function UpdateMoneyFrameWidths(moneyFrame)
    for _, denomination in ipairs(moneyFrame.denominations) do
        local textWidth = math.max(denomination.fontString:GetStringWidth(), denomination.minimumWidth)
        denomination.button:SetWidth(textWidth + MONEY_ICON_WIDTH)
    end
end

local function HideFrameText(frame)
    if not frame or not frame.GetRegions then
        return
    end

    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region.GetFont and region.Hide then
            region:Hide()
        end
    end
end

local function ResizeLevelColumn()
    if BrowseQualitySort and BrowseLevelSort then
        BrowseQualitySort:SetWidth(BrowseQualitySort:GetWidth() + LEVEL_COLUMN_REDUCTION)
        BrowseLevelSort:SetWidth(math.max(1, BrowseLevelSort:GetWidth() - LEVEL_COLUMN_REDUCTION))
    end

    for i = 1, NUM_BROWSE_TO_DISPLAY do
        local rowName = "BrowseButton" .. i
        local itemName = _G[rowName .. "Name"]
        local level = _G[rowName .. "Level"]

        if itemName and level then
            itemName:SetWidth(itemName:GetWidth() + LEVEL_COLUMN_REDUCTION)
            level:SetWidth(math.max(1, level:GetWidth() - LEVEL_COLUMN_REDUCTION))
            level:ClearAllPoints()
            level:SetPoint("TOPLEFT", itemName, "TOPRIGHT", -LEVEL_COLUMN_OVERLAP, 0)
        end
    end
end

local function PrepareRowWidgets()
    for i = 1, NUM_BROWSE_TO_DISPLAY do
        local rowName = "BrowseButton" .. i

        for _, fieldName in ipairs(BROWSE_RESULT_FONT_FIELDS) do
            SetFontSize(_G[rowName .. fieldName], BROWSE_RESULT_FONT_SIZE)
        end

        rowWidgets[i] = {
            row = _G[rowName],
            moneyFrame = PrepareMoneyFrame(rowName .. "MoneyFrame"),
            buyoutMoneyFrame = PrepareMoneyFrame(rowName .. "BuyoutFrameMoney"),
            buyoutFrame = _G[rowName .. "BuyoutFrame"],
            buyoutFrameText = _G[rowName .. "BuyoutFrameText"],
        }
    end
end

local function UpdateBrowseMoneyFrameWidths()
    for i = 1, NUM_BROWSE_TO_DISPLAY do
        local widgets = rowWidgets[i]
        if widgets.moneyFrame then
            UpdateMoneyFrameWidths(widgets.moneyFrame)
        end
        if widgets.buyoutMoneyFrame then
            UpdateMoneyFrameWidths(widgets.buyoutMoneyFrame)
        end
    end
end

local function GetAuctionActions(index)
    local name, _, _, _, _, _, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo(AUCTION_LIST, index)
    if not name then
        local errorMessage = "That auction is no longer available."
        return nil, nil, nil, errorMessage, errorMessage
    end

    local playerMoney = GetMoney()
    local ownAuction = owner == UnitName("player")

    local validBuyout
    local buyoutError
    if not buyoutPrice or buyoutPrice == 0 or not minBid or buyoutPrice < minBid then
        buyoutError = "That auction has no valid buyout price."
    elseif ownAuction then
        buyoutError = "You cannot buy your own auction."
    elseif playerMoney < buyoutPrice and (not highBidder or playerMoney + (bidAmount or 0) < buyoutPrice) then
        buyoutError = "You do not have enough money."
    else
        validBuyout = buyoutPrice
    end

    local requiredBid
    if bidAmount and bidAmount > 0 then
        requiredBid = bidAmount + (minIncrement or 0)
    else
        requiredBid = minBid
    end
    if requiredBid and buyoutPrice and buyoutPrice > 0 and requiredBid > buyoutPrice then
        requiredBid = buyoutPrice
    end

    local validBid
    local bidError
    if not requiredBid or requiredBid <= 0 then
        bidError = "That auction has no valid bid price."
    elseif ownAuction then
        bidError = "You cannot bid on your own auction."
    elseif highBidder then
        bidError = "You are already the highest bidder."
    elseif requiredBid > MAXIMUM_BID_PRICE then
        bidError = "That bid exceeds the maximum allowed price."
    elseif playerMoney < requiredBid then
        bidError = "You do not have enough money."
    else
        validBid = requiredBid
    end

    return validBuyout, validBid, name, buyoutError, bidError
end

local function GetRowAuctionIndex(row)
    return row:GetID() + FauxScrollFrame_GetOffset(BrowseScrollFrame)
end

local function HandleRowAction(self)
    local index = GetRowAuctionIndex(self:GetParent())
    local buyoutPrice, bidPrice, _, buyoutError, bidError = GetAuctionActions(index)

    local price, errorMessage
    if self.synastriaAction == "buyout" then
        price, errorMessage = buyoutPrice, buyoutError
    else
        price, errorMessage = bidPrice, bidError
    end

    if not price then
        ShowError(errorMessage)
        return
    end

    CloseAuctionStaticPopups()
    self:Disable()
    PlaceAuctionBid(AUCTION_LIST, index, price)
end

local function ShowRowTooltip(self)
    local action = ROW_ACTIONS[self.synastriaAction]
    local buyoutPrice, bidPrice, name = GetAuctionActions(GetRowAuctionIndex(self:GetParent()))

    local price
    if self.synastriaAction == "buyout" then
        price = buyoutPrice
    else
        price = bidPrice
    end

    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(action.title, 1, 1, 1)
    if name then
        GameTooltip:AddLine(name, 1, 0.82, 0)
    end
    if price then
        GameTooltip:AddLine(action.enabled, nil, nil, nil, true)
    else
        GameTooltip:AddLine(action.disabled, 1, 0.1, 0.1, true)
    end
    GameTooltip:Show()
end

local function HideRowButtonTooltip()
    GameTooltip:Hide()
end

local function UpdateRowButtons()
    for i = 1, NUM_BROWSE_TO_DISPLAY do
        local widgets = rowWidgets[i]
        local buyoutButton = rowBuyoutButtons[i]
        local bidButton = rowBidButtons[i]

        if widgets.row:IsShown() then
            local buyoutPrice, bidPrice = GetAuctionActions(GetRowAuctionIndex(widgets.row))
            SetEnabled(buyoutButton, buyoutPrice ~= nil)
            SetEnabled(bidButton, bidPrice ~= nil)

            local moneyFrame = widgets.moneyFrame.frame
            local verticalOffset = widgets.buyoutFrame:IsShown() and 10 or 3
            moneyFrame:ClearAllPoints()
            moneyFrame:SetPoint("RIGHT", buyoutButton, "LEFT", PRICE_FRAME_OFFSET, verticalOffset)

            HideFrameText(widgets.buyoutFrameText)
        else
            SetEnabled(buyoutButton, false)
            SetEnabled(bidButton, false)
        end
    end

    UpdateBrowseMoneyFrameWidths()
end

local function CreateRowButton(row, label, action)
    local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    button:SetWidth(ROW_BUTTON_WIDTH)
    button:SetHeight(ROW_BUTTON_HEIGHT)
    button:SetFrameLevel(row:GetFrameLevel() + 2)
    button:SetText(label)
    button.synastriaAction = action
    SetFontSize(button:GetFontString(), ROW_BUTTON_FONT_SIZE)
    button:SetScript("OnClick", HandleRowAction)
    button:SetScript("OnEnter", ShowRowTooltip)
    button:SetScript("OnLeave", HideRowButtonTooltip)
    return button
end

local function CreateRowButtons()
    if rowBuyoutButtons[1] or not AuctionFrameBrowse or not BrowseButton1 then
        return
    end

    ResizeLevelColumn()

    for i = 1, NUM_BROWSE_TO_DISPLAY do
        local row = _G["BrowseButton" .. i]

        local bidButton = CreateRowButton(row, "BID", "bid")
        bidButton:SetPoint("RIGHT", row, "RIGHT", -2, 1)
        rowBidButtons[i] = bidButton

        local buyoutButton = CreateRowButton(row, "BUY", "buyout")
        buyoutButton:SetPoint("RIGHT", bidButton, "LEFT", -ROW_BUTTON_GAP, 0)
        rowBuyoutButtons[i] = buyoutButton
    end

    PrepareRowWidgets()

    hooksecurefunc("AuctionFrameBrowse_Update", UpdateRowButtons)
    eventFrame:RegisterEvent("PLAYER_MONEY")
    UpdateRowButtons()
end

local function HandleEvent(self, event, loadedAddon)
    if event == "PLAYER_MONEY" then
        UpdateRowButtons()
        return
    end

    if event ~= "ADDON_LOADED" or loadedAddon ~= "Blizzard_AuctionUI" then
        return
    end

    self:UnregisterEvent("ADDON_LOADED")
    CreateRowButtons()
end

eventFrame:SetScript("OnEvent", HandleEvent)

if IsAddOnLoaded("Blizzard_AuctionUI") then
    CreateRowButtons()
else
    eventFrame:RegisterEvent("ADDON_LOADED")
end
