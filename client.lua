local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
TargetPed = {}
TargetZone = {}
VendMachine = {}

local IsBusy = false

-- Functions

CreateThread(function()
    for k,v in pairs(Config.Shops) do
        if v ~= nil then
            if v.Enable then
                if v.Locations then
                    for d,j in pairs(v.Locations) do
                        if Config.UsePeds then
                            if j.Ped ~= nil then
                                local model = ''
                                local entity = ''
                                model = j.Ped
                                RequestModel(model)
                                while not HasModelLoaded(model) do
                                  Wait(0)
                                end
                            
                                entity = CreatePed(0, model, j.Coords.x,j.Coords.y,j.Coords.z-1,j.Coords.w, false, false)
                                SetEntityInvincible(entity,true)
                                FreezeEntityPosition(entity,true)
                                SetBlockingOfNonTemporaryEvents(entity,true)
                                TargetPed["Ped"..k..d] = 
                                exports['qb-target']:AddTargetEntity(entity,{
                                    options = {{icon = "fas fa-comment-dots",label = "Talk",action = function() OpenShopMenu(k,v.Products) end,},},
                                    distance = 2.5,
                                })
                                DebugCode("Ped Made For Shop "..tostring(k).." At Coords "..tostring(j.Coords))
                            end
                        else
                            TargetZone["Shop"..k..d] =
	                        exports['qb-target']:AddBoxZone("Shop"..k..d, j.Coords, 4.0, 4.0, {name = "Shop"..k..d,heading = j.Coords.w,debugPoly = Config.DebugPoly,minZ=j.Coords.z-2,maxZ=j.Coords.z+2,}, {
	                        	options = {{icon = v.Icon,label = "Talk",action = function() OpenShopMenu(k,v.Products) end,},},
	                        	distance = 2.5,
	                        })
                            DebugCode("BoxZone Made For Shop "..tostring(k).." At Coords "..tostring(j.Coords))
                        end
                        if j.ShowBlip then
                            blip = AddBlipForCoord(j.Coords)
                            SetBlipAsShortRange(blip, true)
                            SetBlipSprite(blip, v.Blip.Sprite)
                            SetBlipColour(blip, v.Blip.Colour)
                            SetBlipScale(blip, 0.8)
                            SetBlipDisplay(blip, 6)
                            BeginTextCommandSetBlipName('STRING')
                            if not Config.CombineBlips then
                                if v.Blip.Label then AddTextComponentString(v.Blip.Label)
                                else AddTextComponentString("Shop") end
                            else
                                AddTextComponentString("Shop")
                            end
                            EndTextCommandSetBlipName(blip)
                        end
                    end
                end
            end
        end
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
                        DebugCode("PropMadeFor Vending Machine: "..tostring(k))
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
    local columns = {
        {
            header = Config.VendingMachines[machine].Label,
            isMenuHeader = true,
        }
    }
    for k,v in ipairs(products) do
        if QBCore.Shared.Items[v.name] ~= nil then
            local item = {}
            item.header = QBCore.Shared.Items[v.name].label
            local text = "Price: $"
            item.text = text..v.price
            if Config.ShowImages then
                item.icon = v.name
            end
            item.params = {
                event = "sayer-shops:Vend:BuyItem",
                isServer = true,
                args = {
                    item = v.name,
                    price = v.price,
                }
            }
            table.insert(columns,item)
        else
            DebugCode("^2SAYER-SHOPS^7:Cannot Find ^4"..v.name.." ^7in ^4Shared/Items.lua")
        end
    end
    exports['qb-menu']:openMenu(columns)
end

function OpenShopMenu(shop,products)
    local OP = Config.Shops[shop]
    local TAB = Config.Products[products]
    local Job = QBCore.Functions.GetPlayerData().job.name
    local issell = nil
    local shopimage = "<img src=nui://"..Config.ShopLogoLink..shop..".png width=35px style='margin-right: 10px'> "
    local columns = {
        {
            header = shopimage,
            text = OP.Label,
            isMenuHeader = true,
        },
    }
    for k, v in ipairs(TAB) do
        if QBCore.Shared.Items[v.name] ~= nil then
            local item = {}
            item.header = QBCore.Shared.Items[v.name].label
            if Config.ShowImages then
                item.icon = v.name
            end
            local text = ""
            if v.cansell then
                text = text .. "Buy For $" .. v.price .. "</br>Sell For $" .. v.cansell.Price .. "<br>"
                issell = v.cansell
            else
                text = text .. "Buy For $" .. v.price .. " "
                issell = nil
            end
            item.text = text
            item.params = {
                event = 'sayer-shops:PurchaseMenu',
                args = {
                    type = v.name,
                    sell = issell,
                    price = v.price,
                    job = v.requiredJob,
                    gang = v.requiredGang,
                    license = v.requiresLicense,
                }
            }
            table.insert(columns, item)
        else
            DebugCode("^2SAYER-SHOPS^7:Cannot Find ^4"..v.name.." ^7in ^4Shared/Items.lua")
        end
    end

    exports['qb-menu']:openMenu(columns)
end

RegisterNetEvent("sayer-shops:PurchaseMenu", function(args)
    local delmenu = nil
    if args.sell then
        delmenu = exports['qb-input']:ShowInput({
            header = "> "..QBCore.Shared.Items[args.type].label.." <",
	    	submitText = "Complete!",
            inputs = {
                {
                    text = "Amount(#)",    
                    name = "amount",    
                    type = "number",    
                    isRequired = true  
                },
                {
                    text = "Cash/Bank(#)",    
                    name = "account",    
                    type = "radio",    
                    isRequired = true,
                    options = {
                        { value = "cash", text = "Cash" }, 
                        { value = "bank", text = "Bank" },
                        { value = "business", text = "Business Account" },
                    },
                },
                {
                    text = "Sell!",        
                    name = "sell",      
                    type = "radio",     
                    isRequired = true,
                    options = {
                        { value = "true", text = "Yes" }, 
                        { value = "false", text = "No" },
                    },
                },
            }
        })
    else
        delmenu = exports['qb-input']:ShowInput({
            header = "> "..QBCore.Shared.Items[args.type].label.." <",
            submitText = "Buy!",
            inputs = {
                {
                    text = "Amount(#)",    
                    name = "amount",    
                    type = "number",    
                    isRequired = true  
                },
                {
                    text = "Cash/Bank/Business(#)",    
                    name = "account",    
                    type = "radio",    
                    isRequired = true,
                    options = {
                        { value = "cash", text = "Cash" }, 
                        { value = "bank", text = "Bank" },
                        { value = "business", text = "Business Account" },
                    },
                },
            }
        })
    end
    if delmenu ~= nil then
        if delmenu.amount == nil or delmenu.account == nil then return DebugCode("DELMENU NIL") end
        if delmenu.sell ~= nil and delmenu.sell  == 'true' then
            TriggerEvent("sayer-shops:ProcessItem",args.type,tonumber(delmenu.amount),args.sell.Price,delmenu.account,args.job,args.gang,args.license,false)
        else
            TriggerEvent("sayer-shops:ProcessItem",args.type,tonumber(delmenu.amount),args.price,delmenu.account,args.job,args.gang,args.license,true)
        end
    end
end)

function SellItem(item,amount,worth,acc)
    if not IsBusy then
        IsBusy = true
        QBCore.Functions.Progressbar('sayer_shop_sell', 'Selling '..QBCore.Shared.Items[item].label, 2000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = "mp_safehouselost@",
            anim = "package_dropoff",
            }, {}, {}, function() -- Success
            TriggerServerEvent('sayer-shops:SellItem', item,amount,worth,acc)
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
        QBCore.Functions.Progressbar('sayer_shop_buy', 'Buying '..QBCore.Shared.Items[item].label, 2000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = "mp_safehouselost@",
            anim = "package_dropoff",
            }, {}, {}, function() -- Success
            TriggerServerEvent('sayer-shops:BuyItem', item,amount,worth,acc)
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

RegisterNetEvent('sayer-shops:ProcessItem', function(item, amount, worth, acc, job, gang, license, isBuying)
    local fullworth = math.ceil(worth * amount)
    local Job = QBCore.Functions.GetPlayerData().job.name
    DebugCode("Job = " .. Job)
    local Gang = QBCore.Functions.GetPlayerData().gang.name
    DebugCode("Gang = " .. Gang)
    local licenseTable = QBCore.Functions.GetPlayerData().metadata['licences']

    local hasJob = false
    local hasGang = false
    local hasLicense = false

    if job then
        for k, v in pairs(job) do
            DebugCode("Job Required = " .. v)
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
            DebugCode("Gang Required = " .. v)
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

--debug function

function DebugCode(msg)
    if Config.DebugCode then
        print(msg)
    end
end

--used to reset peds/zones when restarting script
AddEventHandler('onResourceStop', function(t) if t ~= GetCurrentResourceName() then return end
	for k in pairs(TargetZone) do exports['qb-target']:RemoveZone(k) end
    for k in pairs(TargetPed) do exports['qb-target']:RemoveTargetEntity(k) end
    for _,v in pairs(VendMachine) do 
        if DoesEntityExist(v) then
            DeleteEntity(v) 
        end
    end
end)