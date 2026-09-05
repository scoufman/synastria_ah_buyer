# Synastria AH Buyer

A small World of Warcraft: Wrath of the Lich King 3.3.5a addon that adds an instant **BUY** button to each visible Auction House browse row.

## Features

- One **BUY** button on every visible auction row
- Purchases the auction on that row without the normal confirmation popup
- Rechecks the auction and buyout price when clicked
- Disables buying for bid-only auctions, your own auctions, and auctions you cannot afford
- Works correctly while scrolling through search results

## Installation

Copy or link this repository into your WoW AddOns directory so the folder and `.toc` file have matching names:

```text
World of Warcraft\Interface\AddOns\synastria_ah_buyer\
├── synastria_ah_buyer.toc
└── SynastriaAHBuyer.lua
```

Restart the client or use `/reload` after updating the addon.

## Usage

1. Open the Auction House.
2. Search for an item.
3. Click **BUY** on the auction row you want.

The purchase is submitted immediately. You do not need to select the row first.

## Warning

There is no confirmation popup. Clicking **BUY** attempts to purchase that auction immediately and cannot be undone. The server may still reject the purchase if the auction has expired or another player bought it first.

## Compatibility

- World of Warcraft 3.3.5a
- Addon interface version `30300`
- Addon version `1.0`
