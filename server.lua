local QBCore = exports['qb-core']:GetCoreObject()
local ShopStock = {}
local RuntimeShops = {}

local function initShopStockForShop(shopId)
    local shop = Config.Shops[shopId]
    if shop and shop.Products and Config.Products[shop.Products] then
        ShopStock[shopId] = ShopStock[shopId] or {}
        for _, product in ipairs(Config.Products[shop.Products]) do
            if product and product.name and product.stock ~= nil then
                ShopStock[shopId][product.name] = math.max(0, math.floor(tonumber(product.stock) or 0))
            end
        end
    end
end

local function initShopStock()
    for shopId in pairs(Config.Shops) do
        initShopStockForShop(shopId)
    end
end

initShopStock()

local function getBusinessBalance(Player)
    local job = Player.PlayerData.job
    if not job or not job.name or job.isboss ~= true then
        return 0
    end
    if GetResourceState('qb-management') ~= 'started' then
        return 0
    end
    return tonumber(exports['qb-management']:GetAccount(job.name) or 0) or 0
end

local function getBalances(Player)
    return {
        cash = tonumber(Player.Functions.GetMoney('cash') or 0) or 0,
        bank = tonumber(Player.Functions.GetMoney('bank') or 0) or 0,
        business = getBusinessBalance(Player),
    }
end

local function hasValue(list, value)
    if type(list) ~= 'table' or not value then
        return true
    end
    for _, entry in ipairs(list) do
        if entry == value then
            return true
        end
    end
    return false
end

local function hasItemAccess(Player, product)
    if type(product.requiredJob) == 'table' and #product.requiredJob > 0 then
        local playerJob = Player.PlayerData.job and Player.PlayerData.job.name or nil
        if not hasValue(product.requiredJob, playerJob) then
            return false, 'Missing required job'
        end
    end

    if type(product.requiredGang) == 'table' and #product.requiredGang > 0 then
        local playerGang = Player.PlayerData.gang and Player.PlayerData.gang.name or nil
        if not hasValue(product.requiredGang, playerGang) then
            return false, 'Missing required gang'
        end
    end

    if product.requiresLicense then
        local metadata = Player.PlayerData.metadata or {}
        local licenses = metadata.licences or metadata.licenses or {}
        if licenses[product.requiresLicense] ~= true then
            return false, 'Missing required license'
        end
    end

    return true, nil
end

local function isSellable(product)
    return product.canSell == true or product.cansell ~= nil
end

local function getSellPercent(shop, product)
    local percent = product.sellPercent or product.SellPercent or shop.SellPercent or 50
    percent = tonumber(percent) or 50
    return math.max(0, math.min(100, percent))
end

local function getSellPrice(shop, product)
    if product.cansell and product.cansell.Price then
        return math.max(0, math.floor(tonumber(product.cansell.Price) or 0))
    end
    return math.max(0, math.floor((tonumber(product.price) or 0) * (getSellPercent(shop, product) / 100)))
end

local function getProductStock(shopId, product)
    if product.stock == nil then
        return nil
    end
    ShopStock[shopId] = ShopStock[shopId] or {}
    if ShopStock[shopId][product.name] == nil then
        ShopStock[shopId][product.name] = math.max(0, math.floor(tonumber(product.stock) or 0))
    end
    return ShopStock[shopId][product.name]
end

local function setProductStock(shopId, product, stock)
    if product.stock == nil then
        return
    end
    ShopStock[shopId] = ShopStock[shopId] or {}
    ShopStock[shopId][product.name] = math.max(0, math.floor(tonumber(stock) or 0))
end

local function adjustProductStock(shopId, product, amount)
    if product.stock == nil then
        return nil
    end
    local current = getProductStock(shopId, product) or 0
    local nextStock = math.max(0, current + amount)
    setProductStock(shopId, product, nextStock)
    return nextStock
end

local function getPlayerItemAmount(Player, itemName)
    local item = Player.Functions.GetItemByName(itemName)
    if not item then
        return 0
    end
    return tonumber(item.amount or item.count or 0) or 0
end

local function getShopPayload(shopId, Player)
    local shop = Config.Shops[shopId]
    if not shop then
        return nil, 'Invalid shop.'
    end

    local productList = Config.Products[shop.Products]
    if type(productList) ~= 'table' then
        return nil, 'Shop has no products configured.'
    end

    local items = {}
    local hasSellables = false

    for _, product in ipairs(productList) do
        local sharedItem = product and product.name and QBCore.Shared.Items[product.name]
        if sharedItem then
            local sellable = isSellable(product)
            local sellPrice = sellable and getSellPrice(shop, product) or 0
            if sellable and sellPrice > 0 then
                hasSellables = true
            end
            items[#items+1] = {
                name = product.name,
                label = sharedItem.label,
                price = math.floor(tonumber(product.price) or 0),
                sellPrice = sellPrice,
                canSell = sellable and sellPrice > 0,
                stock = getProductStock(shopId, product),
                icon = ("nui://qb-inventory/html/images/%s.png"):format(product.name),
            }
        end
    end

    return {
        items = items,
        hasSellables = hasSellables,
        balances = getBalances(Player),
    }, nil
end

local function getShopProductLookup(shopId)
    local shop = Config.Shops[shopId]
    if not shop then
        return nil, 'Invalid shop.'
    end
    local productList = Config.Products[shop.Products]
    if type(productList) ~= 'table' then
        return nil, 'Shop has no products configured.'
    end

    local lookup = {}
    for _, product in ipairs(productList) do
        if product and product.name then
            lookup[product.name] = product
        end
    end

    return lookup, nil
end

local function addStockToShop(shopId, itemName, amount)
    shopId = tostring(shopId or '')
    itemName = tostring(itemName or '')
    amount = math.floor(tonumber(amount) or 0)

    if shopId == '' then
        return { ok = false, reason = 'Invalid shop.' }
    end

    if itemName == '' then
        return { ok = false, reason = 'Invalid item.' }
    end

    if amount <= 0 then
        return { ok = false, reason = 'Amount must be greater than 0.' }
    end

    local lookup, err = getShopProductLookup(shopId)
    if not lookup then
        return { ok = false, reason = err or 'Invalid shop.' }
    end

    local product = lookup[itemName]
    if not product then
        return { ok = false, reason = 'Item is not registered to this shop.' }
    end

    if product.stock == nil then
        return { ok = false, reason = 'Item does not use managed stock.' }
    end

    local oldStock = getProductStock(shopId, product) or 0
    local newStock = adjustProductStock(shopId, product, amount)

    return {
        ok = true,
        shopId = shopId,
        itemName = itemName,
        amount = amount,
        oldStock = oldStock,
        newStock = newStock,
    }
end

exports('AddShopStock', addStockToShop)

local function registerShop(data)
    if type(data) ~= 'table' then
        return { ok = false, reason = 'Shop data must be a table.' }
    end

    local shopId = tostring(data.shopID or data.shopId or data.id or '')
    if shopId == '' then
        return { ok = false, reason = 'Shop data is missing shopID.' }
    end

    if type(data.Products) ~= 'table' then
        return { ok = false, reason = 'Shop data is missing Products table.' }
    end

    local products = data.Products
    local shopData = {
        Enable = data.Enable ~= false,
        Label = data.Label or data.label or shopId,
        Products = shopId,
        SellPercent = data.SellPercent or data.sellPercent,
        Icon = data.Icon or data.icon or "fas fa-comment-dots",
        Blip = data.Blip,
        Locations = data.Locations or {},
        shopLogo = data.shopLogo,
    }

    Config.Products[shopId] = products
    Config.Shops[shopId] = shopData
    ShopStock[shopId] = {}
    initShopStockForShop(shopId)

    RuntimeShops[shopId] = {
        shop = shopData,
        products = products,
    }

    TriggerClientEvent('tss-shops:client:RegisterShop', -1, shopId, shopData, products)

    return {
        ok = true,
        shopID = shopId,
        productCount = #products,
    }
end

local function syncRuntimeShop(src, shopId)
    local runtime = RuntimeShops[shopId]
    if not runtime then
        return false
    end

    TriggerClientEvent('tss-shops:client:RegisterShop', src, shopId, runtime.shop, runtime.products)
    return true
end

local function openShopForPlayer(src, shopId)
    src = tonumber(src)
    shopId = tostring(shopId or '')

    if not src or src <= 0 then
        return { ok = false, reason = 'A valid player source is required.' }
    end

    if shopId == '' or not Config.Shops[shopId] then
        return { ok = false, reason = 'Invalid shop.' }
    end

    syncRuntimeShop(src, shopId)
    TriggerClientEvent('tss-shops:client:OpenShop', src, shopId)

    return {
        ok = true,
        shopID = shopId,
        source = src,
    }
end

exports('registerShop', registerShop)
exports('openShop', openShopForPlayer)
exports('RegisterShop', registerShop)
exports('OpenShop', openShopForPlayer)

local function syncRuntimeShopsToPlayer(src)
    if not src then
        return
    end

    for shopId in pairs(RuntimeShops) do
        syncRuntimeShop(src, shopId)
    end
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player and Player.PlayerData and Player.PlayerData.source
    syncRuntimeShopsToPlayer(src)
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    syncRuntimeShopsToPlayer(source)
end)

local function getAvailableFunds(Player, account)
    if account == 'cash' or account == 'bank' then
        return tonumber(Player.Functions.GetMoney(account) or 0) or 0, nil
    end

    if account == 'business' then
        local job = Player.PlayerData.job
        if not job or not job.name then
            return 0, 'No job account available.'
        end
        if job.isboss ~= true then
            return 0, 'Only bosses can use business account.'
        end
        if GetResourceState('qb-management') ~= 'started' then
            return 0, 'Business account system unavailable.'
        end
        return tonumber(exports['qb-management']:GetAccount(job.name) or 0) or 0, nil
    end

    return 0, 'Invalid account selected.'
end

local function removeFunds(Player, account, amount)
    if amount <= 0 then
        return true
    end
    if account == 'cash' or account == 'bank' then
        return Player.Functions.RemoveMoney(account, amount)
    end
    if account == 'business' then
        local job = Player.PlayerData.job
        if not job or not job.name then
            return false
        end
        if GetResourceState('qb-management') ~= 'started' then
            return false
        end
        return exports['qb-management']:RemoveMoney(job.name, amount)
    end
    return false
end

local function addFunds(Player, account, amount)
    if amount <= 0 then
        return true
    end
    if account == 'cash' or account == 'bank' then
        Player.Functions.AddMoney(account, amount)
        return true
    end
    if account == 'business' then
        local job = Player.PlayerData.job
        if not job or not job.name then
            return false
        end
        if GetResourceState('qb-management') ~= 'started' then
            return false
        end
        exports['qb-management']:AddMoney(job.name, amount)
        return true
    end
    return false
end

local function getVendingProduct(machineId, itemName)
    local machine = Config.VendingMachines[machineId]
    if not machine or machine.Enable ~= true then
        return nil
    end

    if type(machine.Products) ~= 'table' then
        return nil
    end

    for _, product in ipairs(machine.Products) do
        if product and product.name == itemName then
            return product
        end
    end

    return nil
end

QBCore.Functions.CreateCallback('tss-shops:GetShop', function(source, cb, shopId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({ ok = false, reason = 'Player not found.' })
        return
    end

    local payload, err = getShopPayload(shopId, Player)
    if not payload then
        cb({ ok = false, reason = err or 'Unable to load shop.' })
        return
    end

    payload.ok = true
    cb(payload)
end)

QBCore.Functions.CreateCallback('tss-shops:CheckMoney', function(source, cb, money, account)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({ ok = false, reason = 'Player not found.' })
        return
    end

    local total = math.floor(tonumber(money) or 0)
    local selected = account or 'cash'
    local balances = getBalances(Player)

    if total <= 0 then
        cb({
            ok = false,
            reason = 'Invalid basket total.',
            cash = balances.cash,
            bank = balances.bank,
            business = balances.business,
        })
        return
    end

    local funds, reason = getAvailableFunds(Player, selected)
    if reason then
        cb({
            ok = false,
            reason = reason,
            cash = balances.cash,
            bank = balances.bank,
            business = balances.business,
        })
        return
    end

    cb({
        ok = funds >= total,
        reason = funds >= total and nil or 'Insufficient funds.',
        cash = balances.cash,
        bank = balances.bank,
        business = balances.business,
    })
end)

QBCore.Functions.CreateCallback('tss-shops:PurchaseBasket', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({ ok = false, reason = 'Player not found.' })
        return
    end

    data = type(data) == 'table' and data or {}
    local shopId = data.shopId
    local account = data.account or 'cash'
    local requestedItems = type(data.items) == 'table' and data.items or {}

    local lookup, err = getShopProductLookup(shopId)
    if not lookup then
        local balances = getBalances(Player)
        cb({
            ok = false,
            reason = err,
            cash = balances.cash,
            bank = balances.bank,
            business = balances.business,
        })
        return
    end

    local basket = {}
    local total = 0
    local failed = {}

    for _, rawItem in ipairs(requestedItems) do
        local name = tostring(rawItem.name or '')
        local qty = math.floor(tonumber(rawItem.qty) or 0)

        if name ~= '' and qty > 0 then
            qty = math.max(1, math.min(999, qty))
            local product = lookup[name]
            if not product then
                failed[#failed+1] = { name = name, qty = qty, reason = 'Item not sold by this shop.' }
            else
                local allowed, denyReason = hasItemAccess(Player, product)
                if not allowed then
                    failed[#failed+1] = { name = name, qty = qty, reason = denyReason or 'No access to this item.' }
                else
                    local price = math.floor(tonumber(product.price) or 0)
                    if price <= 0 then
                        failed[#failed+1] = { name = name, qty = qty, reason = 'Item has invalid price.' }
                    elseif product.stock ~= nil and (getProductStock(shopId, product) or 0) <= 0 then
                        failed[#failed+1] = { name = name, qty = qty, reason = 'Out of stock.' }
                    else
                        local stock = getProductStock(shopId, product)
                        if stock ~= nil then
                            qty = math.min(qty, stock)
                        end
                        local current = basket[name]
                        if current then
                            current.qty = math.min(999, current.qty + qty)
                            if stock ~= nil then
                                current.qty = math.min(current.qty, stock)
                            end
                        else
                            basket[name] = { qty = qty, price = price, product = product }
                        end
                    end
                end
            end
        end
    end

    local validLines = 0
    for _, row in pairs(basket) do
        validLines = validLines + 1
        total = total + (row.price * row.qty)
    end

    local balancesBefore = getBalances(Player)
    if validLines == 0 or total <= 0 then
        cb({
            ok = false,
            reason = 'Basket contains no purchasable items.',
            failed = failed,
            cash = balancesBefore.cash,
            bank = balancesBefore.bank,
            business = balancesBefore.business,
        })
        return
    end

    local funds, fundsReason = getAvailableFunds(Player, account)
    if fundsReason then
        cb({
            ok = false,
            reason = fundsReason,
            failed = failed,
            cash = balancesBefore.cash,
            bank = balancesBefore.bank,
            business = balancesBefore.business,
        })
        return
    end

    if funds < total then
        cb({
            ok = false,
            reason = 'Insufficient funds.',
            failed = failed,
            cash = balancesBefore.cash,
            bank = balancesBefore.bank,
            business = balancesBefore.business,
        })
        return
    end

    if not removeFunds(Player, account, total) then
        local balances = getBalances(Player)
        cb({
            ok = false,
            reason = 'Unable to take payment.',
            failed = failed,
            cash = balances.cash,
            bank = balances.bank,
            business = balances.business,
        })
        return
    end

    local purchased = {}
    local refunded = 0

    for name, row in pairs(basket) do
        local added = Player.Functions.AddItem(name, row.qty)
        if added == nil then
            added = true
        end

        if added then
            purchased[#purchased+1] = { name = name, qty = row.qty }
            adjustProductStock(shopId, row.product, -row.qty)
            if QBCore.Shared.Items[name] then
                TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[name], "add")
            end
        else
            refunded = refunded + (row.price * row.qty)
            failed[#failed+1] = { name = name, qty = row.qty, reason = 'Inventory full.' }
        end
    end

    if refunded > 0 then
        addFunds(Player, account, refunded)
    end

    local paid = total - refunded
    local balancesAfter = getBalances(Player)

    if #purchased > 0 then
        local playerName = Player.PlayerData.name
        local cid = Player.PlayerData.cid
        SendDiscordMessage(
            "Basket Purchase",
            playerName.." ID( "..cid.." ) purchased "..#purchased.." line(s) for $"..paid.." from "..tostring(shopId).." using "..string.upper(account)..".",
            'orange'
        )
    end

    if #purchased == 0 then
        cb({
            ok = false,
            reason = 'Could not add items to inventory. Full refund issued.',
            failed = failed,
            cash = balancesAfter.cash,
            bank = balancesAfter.bank,
            business = balancesAfter.business,
        })
        return
    end

    cb({
        ok = true,
        partial = #failed > 0,
        reason = #failed > 0 and 'Purchase complete with partial refund for failed items.' or 'Purchase complete.',
        purchased = purchased,
        failed = failed,
        shop = getShopPayload(shopId, Player),
        cash = balancesAfter.cash,
        bank = balancesAfter.bank,
        business = balancesAfter.business,
    })
end)

QBCore.Functions.CreateCallback('tss-shops:SellBasket', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({ ok = false, reason = 'Player not found.' })
        return
    end

    data = type(data) == 'table' and data or {}
    local shopId = data.shopId
    local account = data.account or 'cash'
    local requestedItems = type(data.items) == 'table' and data.items or {}
    local shop = Config.Shops[shopId]
    local lookup, err = getShopProductLookup(shopId)
    local balancesBefore = getBalances(Player)

    if not lookup or not shop then
        cb({
            ok = false,
            reason = err or 'Invalid shop.',
            cash = balancesBefore.cash,
            bank = balancesBefore.bank,
            business = balancesBefore.business,
        })
        return
    end

    local basket = {}
    local failed = {}
    local total = 0

    for _, rawItem in ipairs(requestedItems) do
        local name = tostring(rawItem.name or '')
        local qty = math.floor(tonumber(rawItem.qty) or 0)

        if name ~= '' and qty > 0 then
            qty = math.max(1, math.min(999, qty))
            local product = lookup[name]
            if not product then
                failed[#failed+1] = { name = name, qty = qty, reason = 'Item not accepted by this shop.' }
            elseif not isSellable(product) then
                failed[#failed+1] = { name = name, qty = qty, reason = 'Shop does not buy this item.' }
            else
                local allowed, denyReason = hasItemAccess(Player, product)
                if not allowed then
                    failed[#failed+1] = { name = name, qty = qty, reason = denyReason or 'No access to this item.' }
                else
                    local owned = getPlayerItemAmount(Player, name)
                    local sellPrice = getSellPrice(shop, product)
                    if sellPrice <= 0 then
                        failed[#failed+1] = { name = name, qty = qty, reason = 'Item has invalid sell price.' }
                    elseif owned <= 0 then
                        failed[#failed+1] = { name = name, qty = qty, reason = 'You do not have this item.' }
                    else
                        qty = math.min(qty, owned)
                        local current = basket[name]
                        if current then
                            current.qty = math.min(999, current.qty + qty)
                            current.qty = math.min(current.qty, owned)
                        else
                            basket[name] = { qty = qty, price = sellPrice, product = product }
                        end
                    end
                end
            end
        end
    end

    local validLines = 0
    for _, row in pairs(basket) do
        validLines = validLines + 1
        total = total + (row.price * row.qty)
    end

    if validLines == 0 or total <= 0 then
        cb({
            ok = false,
            reason = 'Basket contains no sellable items.',
            failed = failed,
            cash = balancesBefore.cash,
            bank = balancesBefore.bank,
            business = balancesBefore.business,
        })
        return
    end

    local _, accountReason = getAvailableFunds(Player, account)
    if accountReason then
        cb({
            ok = false,
            reason = accountReason,
            failed = failed,
            cash = balancesBefore.cash,
            bank = balancesBefore.bank,
            business = balancesBefore.business,
        })
        return
    end

    local sold = {}
    for name, row in pairs(basket) do
        if Player.Functions.RemoveItem(name, row.qty) then
            sold[#sold+1] = { name = name, qty = row.qty }
            adjustProductStock(shopId, row.product, row.qty)
            if QBCore.Shared.Items[name] then
                TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[name], "remove")
            end
        else
            failed[#failed+1] = { name = name, qty = row.qty, reason = 'Could not remove item.' }
        end
    end

    local payout = 0
    for _, row in ipairs(sold) do
        local product = lookup[row.name]
        payout = payout + (getSellPrice(shop, product) * row.qty)
    end

    if payout <= 0 or not addFunds(Player, account, payout) then
        cb({
            ok = false,
            reason = 'Could not pay for sold items.',
            failed = failed,
            cash = getBalances(Player).cash,
            bank = getBalances(Player).bank,
            business = getBalances(Player).business,
        })
        return
    end

    local balancesAfter = getBalances(Player)

    if #sold > 0 then
        local playerName = Player.PlayerData.name
        local cid = Player.PlayerData.cid
        SendDiscordMessage(
            "Basket Sale",
            playerName.." ID( "..cid.." ) sold "..#sold.." line(s) for $"..payout.." to "..tostring(shopId).." using "..string.upper(account)..".",
            'orange'
        )
    end

    cb({
        ok = true,
        partial = #failed > 0,
        reason = #failed > 0 and 'Sale complete, but some items were skipped.' or 'Sale complete.',
        sold = sold,
        failed = failed,
        shop = getShopPayload(shopId, Player),
        cash = balancesAfter.cash,
        bank = balancesAfter.bank,
        business = balancesAfter.business,
    })
end)

QBCore.Functions.CreateCallback('tss-shops:PurchaseVending', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({ ok = false, reason = 'Player not found.' })
        return
    end

    data = type(data) == 'table' and data or {}
    local machineId = data.machineId
    local itemName = tostring(data.itemName or '')

    if itemName == '' then
        cb({ ok = false, reason = 'Invalid item selected.' })
        return
    end

    local product = getVendingProduct(machineId, itemName)
    if not product then
        cb({ ok = false, reason = 'Item is not sold by this machine.' })
        return
    end

    local price = math.floor(tonumber(product.price) or 0)
    if price <= 0 then
        cb({ ok = false, reason = 'Invalid vending item price.' })
        return
    end

    local cash = tonumber(Player.Functions.GetMoney('cash') or 0) or 0
    if cash < price then
        cb({ ok = false, reason = 'Not enough cash.' })
        return
    end

    if not Player.Functions.RemoveMoney('cash', price) then
        cb({ ok = false, reason = 'Unable to take payment.' })
        return
    end

    local added = Player.Functions.AddItem(itemName, 1)
    if added == nil then
        added = true
    end

    if not added then
        Player.Functions.AddMoney('cash', price)
        cb({ ok = false, reason = 'Inventory full. Payment refunded.' })
        return
    end

    if QBCore.Shared.Items[itemName] then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], "add")
    end

    cb({ ok = true, reason = 'Purchased '..(QBCore.Shared.Items[itemName] and QBCore.Shared.Items[itemName].label or itemName)..'.' })
end)

RegisterNetEvent('tss-shops:Vend:BuyItem', function(data)
    local item = data.item
    local price = tonumber(data.price)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveMoney('cash',price) then
        Player.Functions.AddItem(item,1)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], "add")
    end
end)

RegisterNetEvent('tss-shops:BuyItem', function(item,amount,worth,account)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Name = Player.PlayerData.name
    local ID = Player.PlayerData.cid
    local fullworth = amount*worth
    if account == 'business' then
        local Job = Player.PlayerData.job.name
        if exports['qb-management']:RemoveMoney(Job,fullworth) then
            Player.Functions.AddItem(item,amount)
            SendDiscordMessage("Items Bought",Name.." ID( "..ID.." ) Bought x"..amount.." "..QBCore.Shared.Items[item].label.." For $"..fullworth.." Using Business Account!", 'orange')
        end
    elseif account == 'cash' or account == 'bank' then
        if Player.Functions.RemoveMoney(account,fullworth) then
            Player.Functions.AddItem(item,amount)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], "add")
            SendDiscordMessage("Items Bought",Name.." ID( "..ID.." ) Bought x"..amount.." "..QBCore.Shared.Items[item].label.." For $"..fullworth.." Money Taken From Their "..string.upper(account).."!", 'orange')
        end
    end
end)

RegisterNetEvent('tss-shops:SellItem', function(item,amount,worth,account)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Name = Player.PlayerData.name
    local ID = Player.PlayerData.cid
    local fullworth = amount*worth
    if account == 'business' then
        local Job = Player.PlayerData.job.name
        if Player.Functions.RemoveItem(item,amount) then
            exports['qb-management']:AddMoney(Job,fullworth)
            SendDiscordMessage("Items Sold",Name.." ID( "..ID.." ) Sold x"..amount.." "..QBCore.Shared.Items[item].label.." For $"..fullworth.." Using Business Account!", 'orange')
        end
    elseif account == 'cash' or account == 'bank' then
        if Player.Functions.RemoveItem(item,amount) then
            Player.Functions.AddMoney(account,fullworth)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], "remove")
            SendDiscordMessage("Items Sold",Name.." ID( "..ID.." ) Sold x"..amount.." "..QBCore.Shared.Items[item].label.." For $"..fullworth.." Money Sent To Their "..string.upper(account).."!", 'orange')
        end
    end
end)

--webhook
local Colors = { -- https://www.spycolor.com/
    ['default'] = 16744192,
    ['blue'] = 255,
    ['red'] = 16711680,
    ['green'] = 65280,
    ['white'] = 16777215,
    ['black'] = 0,
    ['orange'] = 16744192,
    ['yellow'] = 16776960,
    ['pink'] = 16761035,
    ["lightgreen"] = 65309,
}
function SendDiscordMessage(title,message,color)
    if not Config.Webhooks.Enable then return end
    local webhookUrl = Config.Webhooks.URL
    if not webhookUrl or webhookUrl == "" or webhookUrl == "CHANGEME" then return end
    local embedData = {
        {
            ['title'] = title or "TSS Shops",
            ['color'] = Colors[color] or Colors['default'],
            ['footer'] = {
                ['text'] = os.date('%c'),
            },
            ['description'] = message,
            ['author'] = {
                ['name'] = 'TSS Shops',
                ['icon_url'] = 'https://tinysprite-scripts.tebex.io/favicon.ico',
            },
        }
    }
    PerformHttpRequest(webhookUrl, function() end, 'POST', json.encode({ username = 'TSS Shops', embeds = embedData}), { ['Content-Type'] = 'application/json' })
end
