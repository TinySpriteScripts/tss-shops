# |‾‾‾|/‾‾‾\ /‾‾‾\
#   |  \__‾‾\\__‾‾\
#   |   |___/ |___/
# tinysprite-scripts.tebex.io

# [`TSS Shops`] by [TinySprite Scripts (TSS)](https://tinysprite-scripts.tebex.io/) | [Discord](https://discord.gg/ZMFfC54FdJ) | [Support Us](https://ko-fi.com/tinyspritescripts)

A modern QBCore shop system with a custom NUI, buy/sell baskets, managed stock, vending support, and runtime shop exports for external scripts.

---

## 🔧 Support
Need help with setup or encountering issues? Join our Discord: [Join Support Server](https://discord.gg/ZMFfC54FdJ)

---

## 🧰 Installation

- Visit http://tinyspritescripts.gitbook.io/ for installation instructions
- Add `ensure tss-shops` after its dependencies in your server config
- Make sure any item used by a shop exists in your shared items file

---

## 📦 Dependencies
- [QBCore Framework](https://github.com/qbcore-framework/qb-core)
- [qb-target](https://github.com/qbcore-framework/qb-target)
- [jim-bridge](https://github.com/jimathy/jim_bridge)
- [qb-management](https://github.com/qbcore-framework/qb-management) optional, required for business account payments

---

## ✨ Features
- Custom responsive NUI shop interface
- Basket purchasing with cash, bank, and boss business account support
- Sell tab for shops that accept player-sold items
- Configurable shop-level sell percentage
- Product-level sell percentage overrides
- Managed per-product stock
- Buying lowers shop stock
- Selling increases shop stock
- Server export to add stock from external scripts, such as delivery jobs
- Server export to register custom runtime shops from external scripts
- Server/client exports to open registered shops
- Vending machine support
- Ped or target-zone shop interactions
- Optional blips per shop location
- Job, gang, and license restricted products
- Discord webhook logging
- Easy to configure

---

## 🧩 Exports

### Add Stock
```lua
local result = exports['tss-shops']:AddShopStock('247', 'cola', 24)

if not result.ok then
    print(result.reason)
end
```

### Register Runtime Shop
```lua
local result = exports['tss-shops']:registerShop({
    shopID = 'customshop1',
    Label = 'Custom Shop',
    Products = {
        [1] = { name = 'item1', price = 2, stock = 100, canSell = true },
    },
    Icon = 'fas fa-comment-dots',
    Blip = { Sprite = 1, Colour = 1, Label = 'Custom Shop' },
    Locations = {
        { Coords = vector4(0.0, 0.0, 0.0, 0.0), Ped = 'pedmodel', ShowBlip = true },
    },
})
```

### Open Shop
```lua
-- Server side
exports['tss-shops']:openShop(source, 'customshop1')

-- Client side
exports['tss-shops']:openShop('customshop1')
```

---

## ⚠️ Disclaimer

- This script is partly protected with escrow. The escrowed file is encrypted, but all other files are open and editable.
- You **do not** need access to the escrowed file for standard use or customisation.

---

## 📬 Contact

- Tebex: [TinySprite Scripts (TSS)](https://tinysprite-scripts.tebex.io/)
- Discord: [TSS Discord](https://discord.gg/ZMFfC54FdJ)
- Ko-fi: [TSS Ko-Fi](https://ko-fi.com/tinyspritescripts)

---

## 🧾 Changelog

### v2.0
- Added custom NUI shop interface
- Added basket-based buying
- Added sell tab and configurable sell percentages
- Added per-product managed stock
- Added stock changes from buying and selling
- Added vending machine NUI
- Added runtime shop registration exports
- Added stock delivery export
- Added cash, bank, and business account support

### v1.0
- Initial release
- Basic configurable QBCore shops
- Ped and target-zone interactions
- Product restrictions by job, gang, and license

---

**© TinySprite Scripts** — Quality resources built for FiveM servers.
