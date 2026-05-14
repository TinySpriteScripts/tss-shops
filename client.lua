local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
TargetPed = {}
TargetZone = {}
TargetBlip = {}
VendMachine = {}

local IsBusy = false

-- Functions

local function RemoveShopTargets(shop)
    for key, entity in pairs(TargetPed) do
        if key:sub(1, 5 + #shop) == "Ped:"..shop..":" then
            exports['qb-target']:RemoveTargetEntity(entity)
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
            TargetPed[key] = nil
        end
    end

    for key in pairs(TargetZone) do
        if key:sub(1, 6 + #shop) == "Shop:"..shop..":" then
            exports['qb-target']:RemoveZone(key)
            TargetZone[key] = nil
        end
    end

    for key, blip in pairs(TargetBlip) do
        if key:sub(1, 6 + #shop) == "Blip:"..shop..":" then
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
            TargetBlip[key] = nil
        end
    end
end

local function CreateShopTargets(shop, data)
    if not data or data.Enable == false or not data.Locations then
        return
    end

    RemoveShopTargets(shop)

    for d,j in pairs(data.Locations) do
        if Config.UsePeds then
            if j.Ped ~= nil then
                local model = j.Ped
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(0)
                end

                local entity = CreatePed(0, model, j.Coords.x,j.Coords.y,j.Coords.z-1,j.Coords.w, false, false)
                SetEntityInvincible(entity,true)
                FreezeEntityPosition(entity,true)
                SetBlockingOfNonTemporaryEvents(entity,true)
                TargetPed["Ped:"..shop..":"..d] = entity
                exports['qb-target']:AddTargetEntity(entity,{
                    options = {{icon = "fas fa-comment-dots",label = "Talk",action = function() OpenShopMenu(shop,data.Products) end,},},
                    distance = 2.5,
                })
                debugPrint("Ped Made For Shop "..tostring(shop).." At Coords "..tostring(j.Coords))
            end
        else
            TargetZone["Shop:"..shop..":"..d] =
            exports['qb-target']:AddBoxZone("Shop:"..shop..":"..d, j.Coords, 4.0, 4.0, {name = "Shop:"..shop..":"..d,heading = j.Coords.w,debugPoly = Config.DebugPoly,minZ=j.Coords.z-2,maxZ=j.Coords.z+2,}, {
                options = {{icon = data.Icon,label = "Talk",action = function() OpenShopMenu(shop,data.Products) end,},},
                distance = 2.5,
            })
            debugPrint("BoxZone Made For Shop "..tostring(shop).." At Coords "..tostring(j.Coords))
        end
        if j.ShowBlip and data.Blip then
            local blip = AddBlipForCoord(j.Coords)
            SetBlipAsShortRange(blip, true)
            SetBlipSprite(blip, data.Blip.Sprite)
            SetBlipColour(blip, data.Blip.Colour or data.Blip.Color or 0)
            SetBlipScale(blip, 0.8)
            SetBlipDisplay(blip, 6)
            BeginTextCommandSetBlipName('STRING')
            if not Config.CombineBlips then
                if data.Blip.Label then AddTextComponentString(data.Blip.Label)
                else AddTextComponentString("Shop") end
            else
                AddTextComponentString("Shop")
            end
            EndTextCommandSetBlipName(blip)
            TargetBlip["Blip:"..shop..":"..d] = blip
        end
    end
end

local function OpenRegisteredShop(shop)
    local shopData = Config.Shops[shop]
    if not shopData then
        QBCore.Functions.Notify('Shop not found.', 'error')
        return false
    end

    OpenShopMenu(shop, shopData.Products)
    return true
end

CreateThread(function()
    for k,v in pairs(Config.Shops) do
        CreateShopTargets(k, v)
    end
    for k,v in pairs(Config.VendingMachines) do
        if v.Enable then
            local label = "Vending Machine"
            if v.Label then
                label = v.Label
            end
            if v.ExtraLocations then
                for d,j in pairs(v.ExtraLocations) do
                    if j.Coords ~= nil then
                        local model = ''
                        model = k
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                          Wait(0)
                        end
                        VendMachine["Vend"..k..d] = CreateObject(GetHashKey(model), vector3(j.Coords.x, j.Coords.y, j.Coords.z - 1), false, false, true)
                        PlaceObjectOnGroundProperly(VendMachine["Vend"..k..d])
                        SetEntityHeading(VendMachine["Vend"..k..d], j.Coords.w)
                        FreezeEntityPosition(VendMachine["Vend"..k..d], true)
                        SetEntityAsMissionEntity(VendMachine["Vend"..k..d])
                        debugPrint("PropMadeFor Vending Machine: "..tostring(k))
                    end
                end
            end
            exports['qb-target']:AddTargetModel(k, {
                options = {
                    {
                        action = function()
                            OpenVendingMachine(k,v.Products)
                        end,
                        icon = "fas fa-sack-dollar",
                        label = "Use "..label,
                    },
                },
                distance = 2.5
            })
        end
    end
end)

function OpenVendingMachine(machine,products)
    if not Config.VendingMachines[machine] then return end

    local items = {}
    for _,v in ipairs(products) do
        if QBCore.Shared.Items[v.name] ~= nil then
            items[#items+1] = {
                name = v.name,
                label = QBCore.Shared.Items[v.name].label,
                price = v.price,
                icon = ("nui://qb-inventory/html/images/%s.png"):format(v.name)
            }
        else
            debugPrint("^2TSS-SHOPS^7: Cannot find ^4"..v.name.." ^7in ^4Shared/Items.lua")
        end
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openVending',
        payload = {
            machineId = machine,
            label = Config.VendingMachines[machine].Label or 'Vending Machine',
            subtitle = 'Select an item to purchase',
            items = items,
        }
    })
end

function OpenShopMenu(shop,products)
    if not Config.Shops[shop] or not Config.Products[products] then
        return
    end

    local logoValue = nil
    local playerData = QBCore.Functions.GetPlayerData()
    local balances = {
        cash = playerData.money['cash'] or 0,
        bank = playerData.money['bank'] or 0,
        business = 0,
    }
    local accounts = { 'cash', 'bank' }

    SetNuiFocus(true, true)
    if Config.Shops[shop].shopLogo then
        logoValue = "nui://tss-shops/html/images/"..Config.Shops[shop].shopLogo
    end

    if playerData.job and playerData.job.isboss == true then
        accounts[#accounts+1] = 'business'
    end

    QBCore.Functions.TriggerCallback('tss-shops:GetShop', function(result)
        if not result or result.ok ~= true then
            SetNuiFocus(false, false)
            QBCore.Functions.Notify(result and result.reason or 'Unable to open shop.', 'error')
            return
        end

        SendNUIMessage({
            action = 'openShop',
            payload = {
                shopId = shop,
                shopLabel = Config.Shops[shop].Label,
                shopSubtitle = 'Browse items and checkout',
                shopLogo = logoValue,
                items = result.items or {},
                hasSellables = result.hasSellables == true,
                balances = result.balances or balances,
                accounts = accounts,
                defaultAccount = 'cash'
            }
        })
    end, shop)

end

-- client
RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('checkFunds', function(data, cb)
    local total = tonumber(data.total or 0)
    local account = data.account or 'cash'
    QBCore.Functions.TriggerCallback('tss-shops:CheckMoney', function(result)
        cb(result or { ok = false, reason = 'Unable to check funds.' })
    end, total, account)
end)

RegisterNUICallback('purchaseBasket', function(data, cb)
    QBCore.Functions.TriggerCallback('tss-shops:PurchaseBasket', function(result)
        cb(result or { ok = false, reason = 'Purchase failed.' })
    end, {
        shopId = data.shopId,
        account = data.account,
        items = data.items
    })
end)

RegisterNUICallback('sellBasket', function(data, cb)
    QBCore.Functions.TriggerCallback('tss-shops:SellBasket', function(result)
        cb(result or { ok = false, reason = 'Sale failed.' })
    end, {
        shopId = data.shopId,
        account = data.account,
        items = data.items
    })
end)

RegisterNUICallback('purchaseVendingItem', function(data, cb)
    QBCore.Functions.TriggerCallback('tss-shops:PurchaseVending', function(result)
        cb(result or { ok = false, reason = 'Purchase failed.' })
    end, {
        machineId = data.machineId,
        itemName = data.itemName
    })
end)

RegisterNetEvent('tss-shops:client:RegisterShop', function(shop, shopData, products)
    if not shop or type(shopData) ~= 'table' or type(products) ~= 'table' then
        return
    end

    Config.Products[shopData.Products] = products
    Config.Shops[shop] = shopData
    CreateShopTargets(shop, shopData)
end)

RegisterNetEvent('tss-shops:client:OpenShop', function(shop)
    OpenRegisteredShop(shop)
end)

exports('openShop', OpenRegisteredShop)


function SellItem(item,amount,worth,acc)
    if not IsBusy then
        IsBusy = true
        QBCore.Functions.Progressbar('tss_shop_sell', 'Selling '..QBCore.Shared.Items[item].label, 2000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = "mp_safehouselost@",
            anim = "package_dropoff",
            }, {}, {}, function() -- Success
            TriggerServerEvent('tss-shops:SellItem', item,amount,worth,acc)
            TriggerEvent('animations:client:EmoteCommandStart', {"c"})
            ClearPedTasks(PlayerPedId())
            IsBusy = false
        end, function() -- Cancel
            ClearPedTasks(PlayerPedId())
            QBCore.Functions.Notify('You have Cancelled The Selling Process', 'error')
            IsBusy = false
        end)
    else
        QBCore.Functions.Notify("You Are Busy",'error')
    end
end

function BuyItem(item,amount,worth,acc)
    if not IsBusy then
        IsBusy = true
        QBCore.Functions.Progressbar('tss_shop_buy', 'Buying '..QBCore.Shared.Items[item].label, 2000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = "mp_safehouselost@",
            anim = "package_dropoff",
            }, {}, {}, function() -- Success
            TriggerServerEvent('tss-shops:BuyItem', item,amount,worth,acc)
            TriggerEvent('animations:client:EmoteCommandStart', {"c"})
            ClearPedTasks(PlayerPedId())
            IsBusy = false
        end, function() -- Cancel
            ClearPedTasks(PlayerPedId())
            QBCore.Functions.Notify('You have Cancelled The Buying Process', 'error')
            IsBusy = false
        end)
    else
        QBCore.Functions.Notify("You Are Busy",'error')
    end
end

RegisterNetEvent('tss-shops:ProcessItem', function(item, amount, worth, acc, job, gang, license, isBuying)
    local fullworth = math.ceil(worth * amount)
    local Job = QBCore.Functions.GetPlayerData().job.name
    debugPrint("Job = " .. Job)
    local Gang = QBCore.Functions.GetPlayerData().gang.name
    debugPrint("Gang = " .. Gang)
    local licenseTable = QBCore.Functions.GetPlayerData().metadata['licences']

    local hasJob = false
    local hasGang = false
    local hasLicense = false

    if job then
        for k, v in pairs(job) do
            debugPrint("Job Required = " .. v)
            if Job == v then
                hasJob = true
                break
            end
        end
    else
        hasJob = true -- No job requirement, so assume the player has the job
    end

    if gang then
        for k, v in pairs(gang) do
            debugPrint("Gang Required = " .. v)
            if Gang == v then
                hasGang = true
                break
            end
        end
    else
        hasGang = true -- No gang requirement, so assume the player has a different gang
    end

    if license then
        if licenseTable[license] == true then
            hasLicense = true
        end
    else
        hasLicense = true -- No license requirement, so assume the player has the required license
    end

    if isBuying then
        if hasJob or hasGang or hasLicense then
            BuyItem(item, amount, worth, acc)
        else
            QBCore.Functions.Notify('You Must Meet the Required Job, Gang, or License to Buy This!', 'error')
        end
    else
        if QBCore.Functions.HasItem(item, amount) then
            if hasJob or hasGang or hasLicense then
                SellItem(item, amount, worth, acc)
            else
                QBCore.Functions.Notify('You Must Meet the Required Job, Gang, or License to Sell This!', 'error')
            end
        else
            QBCore.Functions.Notify("You Don't Have This Item To Sell!", "error")
            return
        end
    end
end)

--used to reset peds/zones when restarting script
AddEventHandler('onResourceStop', function(t) if t ~= GetCurrentResourceName() then return end
	for k in pairs(TargetZone) do exports['qb-target']:RemoveZone(k) end
    for _,v in pairs(TargetPed) do
        exports['qb-target']:RemoveTargetEntity(v)
        if DoesEntityExist(v) then
            DeleteEntity(v)
        end
    end
    for _,v in pairs(TargetBlip) do
        if DoesBlipExist(v) then
            RemoveBlip(v)
        end
    end
    for _,v in pairs(VendMachine) do 
        if DoesEntityExist(v) then
            DeleteEntity(v) 
        end
    end
end)
