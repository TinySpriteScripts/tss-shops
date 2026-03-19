local QBCore = exports['qb-core']:GetCoreObject()

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

QBCore.Functions.CreateCallback('sayer-shops:CheckMoney', function(source, cb, money, account)
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

QBCore.Functions.CreateCallback('sayer-shops:PurchaseBasket', function(source, cb, data)
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
                    else
                        local current = basket[name]
                        if current then
                            current.qty = math.min(999, current.qty + qty)
                        else
                            basket[name] = { qty = qty, price = price }
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
        cash = balancesAfter.cash,
        bank = balancesAfter.bank,
        business = balancesAfter.business,
    })
end)

QBCore.Functions.CreateCallback('sayer-shops:PurchaseVending', function(source, cb, data)
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

RegisterNetEvent('sayer-shops:Vend:BuyItem', function(data)
    local item = data.item
    local price = tonumber(data.price)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveMoney('cash',price) then
        Player.Functions.AddItem(item,1)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], "add")
    end
end)

RegisterNetEvent('sayer-shops:BuyItem', function(item,amount,worth,account)
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

RegisterNetEvent('sayer-shops:SellItem', function(item,amount,worth,account)
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
local webhookUrl = Config.Webhooks.URL 
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
    if Config.Webhooks.Enable then
        local embedData = {
            {
                ['title'] = title or "Sayer Shops",
                ['color'] = Colors[color] or Colors['default'],
                ['footer'] = {
                    ['text'] = os.date('%c'),
                },
                ['description'] = message,
                ['author'] = {
                    ['name'] = 'Sayer Shops',
                    ['icon_url'] = 'https://cdn.discordapp.com/attachments/1061012675112476672/1061012749133565962/oosayerooscriptspng.png',
                },
            }
        }
        PerformHttpRequest(webhookUrl, function() end, 'POST', json.encode({ username = 'Sayer Shops', embeds = embedData}), { ['Content-Type'] = 'application/json' })
    end
end
