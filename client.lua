Citizen.CreateThread(function()
    exports.ox_target:addModel(Config.ATMProps, {
        icon = 'fas fa-money-bill',
        label = 'Skorzystaj z Bankomatu',
        onSelect = function(data)
            NetworkRegisterEntityAsNetworked(data.entity)
            OpenMenu(data.entity)
        end,
        distance = 2
	})
    for _, v in pairs(Config.Banks) do
        local blip = AddBlipForCoord(v.position)
        SetBlipSprite(blip, 277)
        SetBlipScale(blip, 1.0)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 15)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('Bank')
        EndTextCommandSetBlipName(blip)
        exports.ox_target:addBoxZone({
            coords = v.position,
            size = v.size,
            rotation = v.rotation,
            debug = false,
            drawSprite = true,
            options = {
                {
                    icon = 'fas fa-money-bill',
                    label = 'Skorzystaj z Banku',
                    onSelect = function()
                        OpenMenu(false)
                    end,
                    distance = 2
                }
            }
        })
    end
end)

OpenMenu = function(IsATM)
    ESX.TriggerServerCallback('yesk_banking:GetPlayerData', function(data)
        if data then
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'open',
                data = data,
                IsATM = IsATM
            })
        end
    end)
end

RegisterNUICallback('Close', function()
    SetNuiFocus(false, false)
end)

RegisterNUICallback('GetAccountData', function(data, cb)
    ESX.TriggerServerCallback('yesk_banking:GetAccountData', function(callback)
        cb(callback)
    end, data.account)
end)


RegisterNUICallback('Action', function(data, cb)
    data.isATM = data.isATM and ObjToNet(data.isATM) or false
    ESX.TriggerServerCallback('yesk_banking:Action', function(callback)
        cb(callback)
    end, data)
end)