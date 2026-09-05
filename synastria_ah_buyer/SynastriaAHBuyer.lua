local AUCTION_LIST = "list"
local ROW_BUTTON_WIDTH = 46
local PRICE_OFFSET = -(ROW_BUTTON_WIDTH + 6)

local eventFrame = CreateFrame("Frame")
local rowBuyoutButtons = {}

local function ShowError(message)
    UIErrorsFrame:AddMessage(message, 1, 0.1, 0.1)
end

local function GetBuyout(index)
    local name, _, _, _, _, _, minBid, _, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo(AUCTION_LIST, index)
    if not name then
        return nil, nil, "That auction is no longer available."
    end

    if not buyoutPrice or buyoutPrice == 0 or not minBid or buyoutPrice < minBid then
        return nil, name, "That auction has no valid buyout price."
    end

    if owner == UnitName("player") then
        return nil, name, "You cannot buy your own auction."
    end

    local playerMoney = GetMoney()
    if playerMoney < buyoutPrice and (not highBidder or playerMoney + (bidAmount or 0) < buyoutPrice) then
        return nil, name, "You do not have enough money."
    end

    return buyoutPrice, name
end

local function GetRowAuctionIndex(row)
    return row:GetID() + FauxScrollFrame_GetOffset(BrowseScrollFrame)
end

local function BuyoutRowAuction(self)
    local index = GetRowAuctionIndex(self:GetParent())
    local buyoutPrice, _, errorMessage = GetBuyout(index)
    if not buyoutPrice then
        ShowError(errorMessage)
        return
    end

    CloseAuctionStaticPopups()
    self:Disable()

    PlaceAuctionBid(AUCTION_LIST, index, buyoutPrice)
end

local function ShowRowButtonTooltip(self)
    local buyoutPrice, name = GetBuyout(GetRowAuctionIndex(self:GetParent()))

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

local function UpdateRowBuyoutButtons()
    for i = 1, NUM_BROWSE_TO_DISPLAY do
        local row = _G["BrowseButton" .. i]
        local button = rowBuyoutButtons[i]

        if row:IsShown() then
            local buyoutPrice = GetBuyout(GetRowAuctionIndex(row))
            if buyoutPrice then
                button:Enable()
            else
                button:Disable()
            end

            local buyoutFrame = _G["BrowseButton" .. i .. "BuyoutFrame"]
            local moneyFrame = _G["BrowseButton" .. i .. "MoneyFrame"]
            local verticalOffset = buyoutFrame:IsShown() and 10 or 3
            moneyFrame:ClearAllPoints()
            moneyFrame:SetPoint("RIGHT", row, "RIGHT", PRICE_OFFSET, verticalOffset)
        else
            button:Disable()
        end
    end
end

local function CreateRowBuyoutButtons()
    if rowBuyoutButtons[1] or not AuctionFrameBrowse or not BrowseButton1 then
        return
    end

    for i = 1, NUM_BROWSE_TO_DISPLAY do
        local row = _G["BrowseButton" .. i]
        local button = CreateFrame(
            "Button",
            "SynastriaAHBuyerRowBuyoutButton" .. i,
            row,
            "UIPanelButtonTemplate"
        )
        button:SetWidth(ROW_BUTTON_WIDTH)
        button:SetHeight(20)
        button:SetPoint("RIGHT", row, "RIGHT", -2, 1)
        button:SetFrameLevel(row:GetFrameLevel() + 2)
        button:SetText("BUY")
        button:SetScript("OnClick", BuyoutRowAuction)
        button:SetScript("OnEnter", ShowRowButtonTooltip)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        rowBuyoutButtons[i] = button
    end

    hooksecurefunc("AuctionFrameBrowse_Update", UpdateRowBuyoutButtons)
    UpdateRowBuyoutButtons()
end

eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == "Blizzard_AuctionUI" then
        CreateRowBuyoutButtons()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
eventFrame:RegisterEvent("ADDON_LOADED")

if IsAddOnLoaded("Blizzard_AuctionUI") then
    CreateRowBuyoutButtons()
    eventFrame:UnregisterEvent("ADDON_LOADED")
end
