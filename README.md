# Synastria AH Buyer

A small World of Warcraft: Wrath of the Lich King 3.3.5a addon that adds instant **BUY** and **BID** buttons to each visible Auction House browse row.

## Preview

![Auction House item rows with instant BUY and BID buttons](assets/auction-house-buy-buttons.webp)

## Features

- Compact **BUY** and **BID** buttons on every visible auction row
- Consistent font sizing and vertically aligned gold, silver, and copper columns in Auction House browse results
- Narrower level column gives auction item names more room (might use the extra space in the future differently)
- **BUY** purchases the auction without the normal confirmation popup
- **BID** places the minimum bid currently accepted by the auction
- Rechecks the auction and price when either button is clicked
- Disables actions for auctions you own, prices you cannot afford, and bids where you are already the highest bidder; affordability refreshes whenever your money changes
- Works correctly while scrolling through search results

## Installation

### Release ZIP

The easiest option is to open the [latest release](https://github.com/scoufman/synastria_ah_buyer/releases/latest) and download the attached `synastria_ah_buyer-v1.5.zip` file.

Extract the ZIP and copy its `synastria_ah_buyer` folder into your WoW AddOns directory.

### Source code ZIP

You can also use GitHub's **Code → Download ZIP** option. Extract the repository archive, then copy the inner `synastria_ah_buyer` folder into your WoW AddOns directory.

The source archive is arranged like this:

```text
synastria_ah_buyer-main\
├── README.md
└── synastria_ah_buyer\
    ├── synastria_ah_buyer.toc
    └── SynastriaAHBuyer.lua
```

After either installation method, your WoW installation should contain:

```text
World of Warcraft\Interface\AddOns\synastria_ah_buyer\
├── synastria_ah_buyer.toc
└── SynastriaAHBuyer.lua
```

Restart the client or use `/reload` after updating the addon.

## Usage

1. Open the Auction House.
2. Search for an item.
3. Click **BUY** to purchase the auction, or **BID** to place its minimum accepted bid.

The action is submitted immediately. You do not need to select the row first.

## Warning

There is no confirmation popup. Clicking **BUY** attempts to purchase the auction immediately, and clicking **BID** immediately places the minimum accepted bid. The server may still reject either action if the auction has expired or its state changed.

## Compatibility

- World of Warcraft 3.3.5a
- Addon interface version `30300`
- Addon version `1.5`
