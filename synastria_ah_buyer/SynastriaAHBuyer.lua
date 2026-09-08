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
    "Gold",
    "Silver",
    "Copper",
}

local LEVEL_COLUMN_REDUCTION = 22
local LEVEL_COLUMN_OVERLAP = 5
local BROWSE_RESULT_FONT_FIELDS = {
    "Name",
    "Level",
    "ClosingTimeText",
    "HighBidder",
}

local eventFrame = CreateFrame("Frame")
local rowBuyoutButtons = {}
local rowBidButtons = {}

local function ShowError(message)
    UIErrorsFrame:AddMessage(message, 1, 0.1, 0.1)
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

local function SetMoneyFrameFontSize(frameName)
    for _, denomination in ipairs(MONEY_DENOMINATIONS) do
        local buttonName = frameName .. denomination .. "Button"
        local button = _G[buttonName]
        if button then
            local fontString = button:GetFontString() or _G[buttonName .. "Text"]
            SetFontSize(fontString, PRICE_FONT_SIZE)

            if fontString then
                button:SetWidth(fontString:GetStringWidth() + MONEY_ICON_WIDTH)
            end
        end
    end
end

local function HideFrameText(frame)
    if not frame then
        return
    end

    if frame.GetFont then
        frame:Hide()
        return
    end

    if frame.GetFontString then
        local fontString = frame:GetFontString()
        if fontString then
            fontString:Hide()
        end
    end

    if not frame.GetRegions then
        return
    end

    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
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

local function SetBrowseResultFontSize()
    for i = 1, NUM_BROWSE_TO_DISPLAY do
        local rowName = "BrowseButton" .. i

        for _, fieldName in ipairs(BROWSE_RESULT_FONT_FIELDS) do
            SetFontSize(_G[rowName .. fieldName], BROWSE_RESULT_FONT_SIZE)
        end

        SetMoneyFrameFontSize(rowName .. "MoneyFrame")
        SetMoneyFrameFontSize(rowName .. "BuyoutMoneyFrame")
        SetMoneyFrameFontSize(rowName .. "BuyoutFrameMoney")
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

local function BuyoutRowAuction(self)
    local index = GetRowAuctionIndex(self:GetParent())
    local buyoutPrice, _, _, errorMessage = GetAuctionActions(index)
    if not buyoutPrice then
        ShowError(errorMessage)
        return
    end

    CloseAuctionStaticPopups()
    self:Disable()
    PlaceAuctionBid(AUCTION_LIST, index, buyoutPrice)
end

local function BidOnRowAuction(self)
    local index = GetRowAuctionIndex(self:GetParent())
    local _, bidPrice, _, _, errorMessage = GetAuctionActions(index)
    if not bidPrice then
        ShowError(errorMessage)
        return
    end

    CloseAuctionStaticPopups()
    self:Disable()
    PlaceAuctionBid(AUCTION_LIST, index, bidPrice)
end

local function ShowBuyoutTooltip(self)
    local buyoutPrice, _, name = GetAuctionActions(GetRowAuctionIndex(self:GetParent()))

    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Instant Buyout", 1, 1, 1)
    if name then
        GameTooltip:AddLine(name, 1, 0.82, 0)
    end
    if buyoutPrice then
        GameTooltip:AddLine("Click to buy this auction immediately.", nil, nil, nil, true)
    else
        GameTooltip:AddLine("This auction cannot currently be bought.", 1, 0.1, 0.1, true)
    end
    GameTooltip:Show()
end

local function ShowBidTooltip(self)
    local _, bidPrice, name = GetAuctionActions(GetRowAuctionIndex(self:GetParent()))

    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Minimum Bid", 1, 1, 1)
    if name then
        GameTooltip:AddLine(name, 1, 0.82, 0)
    end
    if bidPrice then
        GameTooltip:AddLine("Click to place the minimum allowed bid.", nil, nil, nil, true)
    else
        GameTooltip:AddLine("You cannot currently bid on this auction.", 1, 0.1, 0.1, true)
    end
    GameTooltip:Show()
end

local function HideRowButtonTooltip()
    GameTooltip:Hide()
end

local function UpdateRowButtons()
    for i = 1, NUM_BROWSE_TO_DISPLAY do
        local row = _G["BrowseButton" .. i]
        local buyoutButton = rowBuyoutButtons[i]
        local bidButton = rowBidButtons[i]

        if row:IsShown() then
            local buyoutPrice, bidPrice = GetAuctionActions(GetRowAuctionIndex(row))
            if buyoutPrice then
                buyoutButton:Enable()
            else
                buyoutButton:Disable()
            end
            if bidPrice then
                bidButton:Enable()
            else
                bidButton:Disable()
            end

            local buyoutFrame = _G["BrowseButton" .. i .. "BuyoutFrame"]
            local buyoutText = _G["BrowseButton" .. i .. "BuyoutText"]
            local buyoutFrameText = _G["BrowseButton" .. i .. "BuyoutFrameText"]
            local moneyFrame = _G["BrowseButton" .. i .. "MoneyFrame"]
            local verticalOffset = buyoutFrame:IsShown() and 10 or 3
            moneyFrame:ClearAllPoints()
            moneyFrame:SetPoint("RIGHT", buyoutButton, "LEFT", PRICE_FRAME_OFFSET, verticalOffset)

            HideFrameText(buyoutFrame)
            HideFrameText(buyoutText)
            HideFrameText(buyoutFrameText)
        else
            buyoutButton:Disable()
            bidButton:Disable()
        end
    end

    SetBrowseResultFontSize()
end

local function CreateRowButtons()
    if rowBuyoutButtons[1] or not AuctionFrameBrowse or not BrowseButton1 then
        return
    end

    ResizeLevelColumn()

    for i = 1, NUM_BROWSE_TO_DISPLAY do
        local row = _G["BrowseButton" .. i]
        local bidButton = CreateFrame(
            "Button",
            "SynastriaAHBuyerRowBidButton" .. i,
            row,
            "UIPanelButtonTemplate"
        )
        bidButton:SetWidth(ROW_BUTTON_WIDTH)
        bidButton:SetHeight(ROW_BUTTON_HEIGHT)
        bidButton:SetPoint("RIGHT", row, "RIGHT", -2, 1)
        bidButton:SetFrameLevel(row:GetFrameLevel() + 2)
        bidButton:SetText("BID")
        SetFontSize(bidButton:GetFontString(), ROW_BUTTON_FONT_SIZE)
        bidButton:SetScript("OnClick", BidOnRowAuction)
        bidButton:SetScript("OnEnter", ShowBidTooltip)
        bidButton:SetScript("OnLeave", HideRowButtonTooltip)
        rowBidButtons[i] = bidButton

        local buyoutButton = CreateFrame(
            "Button",
            "SynastriaAHBuyerRowBuyoutButton" .. i,
            row,
            "UIPanelButtonTemplate"
        )
        buyoutButton:SetWidth(ROW_BUTTON_WIDTH)
        buyoutButton:SetHeight(ROW_BUTTON_HEIGHT)
        buyoutButton:SetPoint("RIGHT", bidButton, "LEFT", -ROW_BUTTON_GAP, 0)
        buyoutButton:SetFrameLevel(row:GetFrameLevel() + 2)
        buyoutButton:SetText("BUY")
        SetFontSize(buyoutButton:GetFontString(), ROW_BUTTON_FONT_SIZE)
        buyoutButton:SetScript("OnClick", BuyoutRowAuction)
        buyoutButton:SetScript("OnEnter", ShowBuyoutTooltip)
        buyoutButton:SetScript("OnLeave", HideRowButtonTooltip)
        rowBuyoutButtons[i] = buyoutButton
    end

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
