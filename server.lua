ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback("yesk_banking:GetPlayerData", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local access = false 
    local jobname = xPlayer.job.label
    
    if xPlayer.job.grade_name == "boss" then access = true end
        local playerdata = {
            Jobs = {
                ['job'] = {
                    [0] = access,
                    [1] = 'police',
                    [2] = jobname
                }
            }
        }
        cb(playerdata)
end)

function AddHistory(player, senderName, sender, action, money)
    local xPlayer = ESX.GetPlayerFromId(player)
    MySQL.Sync.insert("INSERT INTO `yesk_history` (`identifier`, `senderName`, `sender`, `action`, `money`, `date`) VALUES (@identifier, @senderName, @sender, @action, @money, @date)", {
        ["@identifier"] = xPlayer.identifier,
        ["@senderName"] = senderName,
        ["@sender"] = sender,
        ["@action"] = action,
        ["@money"] = money,
        ["@date"] = os.date("%Y-%m-%d %H:%M:%S")
    })
end

RegisterServerEvent('yesk_banking:AddHistory')
AddEventHandler('yesk_banking:AddHistory', function(player, senderName, sender, action, money)
    AddHistory(player, senderName, sender, action, money)
end)

exports("AddHistory", AddHistory)

function AddSocietyHistory(society, senderName, sender, action, money)
    TriggerEvent('esx_addonaccount:getSharedAccount', society, function(account)
        if account then
            MySQL.Sync.insert("INSERT INTO `yesk_history` (`identifier`, `senderName`, `sender`, `action`, `money`, `date`) VALUES (@identifier, @senderName, @sender, @action, @money, @date)", {
                ["@identifier"] = society,
                ["@senderName"] = senderName,
                ["@sender"] = sender,
                ["@action"] = action,
                ["@money"] = money,
                ["@date"] = os.date("%Y-%m-%d %H:%M:%S")
            })
        end
    end)
end

RegisterServerEvent('yesk_banking:AddSocietyHistory')
AddEventHandler('yesk_banking:AddSocietyHistory', function(society, senderName, sender, action, money)
    AddSocietyHistory(society, senderName, sender, action, money)
end)

exports("AddSocietyHistory", AddSocietyHistory)

function GetSocietyHistory(player, _type)
    local result = MySQL.query.await('SELECT * FROM yesk_history WHERE identifier = ?', {
        _type == 'self' and ESX.GetPlayerFromId(player).identifier or player
    })
    local History = {}
    for i=1, #result, 1 do
        table.insert(History, {
            senderName = result[i].senderName,
            sender = result[i].sender,
            action = result[i].action,
            money = result[i].money,
            date = result[i].date
        })
    end
    return History
end

function Get7DaysHistory(player)
    local currentDate = os.date('%Y-%m-%d %H:%M:%S')
    local xPlayer = ESX.GetPlayerFromId(player)

    local query = "SELECT * FROM yesk_history WHERE identifier = @identifier AND date >= DATE_SUB(NOW(), INTERVAL 7 DAY) ORDER BY date DESC"
    local params = {['@identifier'] = xPlayer.identifier}

    local result = MySQL.query.await(query, params)

    local totalMoney = 0

    if result and #result > 0 then
        for _, record in ipairs(result) do
            local moneyValue = tonumber(record.money) or 0

            if record.action == "transfer" or record.action == "deposit" then
                totalMoney = totalMoney + moneyValue
            elseif record.action == "withdraw" then
                totalMoney = totalMoney - moneyValue
            end
        end
    end
    return totalMoney
end

function Get7DaySocietyHistory(society)
    local currentDate = os.date('%Y-%m-%d %H:%M:%S')
    local xPlayer = ESX.GetPlayerFromId(player)

    local query = "SELECT * FROM yesk_history WHERE identifier = @identifier AND date >= DATE_SUB(NOW(), INTERVAL 7 DAY) ORDER BY date DESC"
    local params = {['@identifier'] = society}

    local result = MySQL.query.await(query, params)

    local totalMoney = 0

    if result and #result > 0 then
        for _, record in ipairs(result) do
            local moneyValue = tonumber(record.money) or 0

            if record.action == "transfer" or record.action == "deposit" then
                totalMoney = totalMoney + moneyValue
            elseif record.action == "withdraw" then
                totalMoney = totalMoney - moneyValue
            end
        end
    end
    return totalMoney
end


function GetHistory(player, _type)
    local result = MySQL.query.await('SELECT * FROM yesk_history WHERE identifier = ?', {
        _type == 'self' and ESX.GetPlayerFromId(player).identifier or player
    })
    local History = {}
    for i=1, #result, 1 do
        table.insert(History, {
            senderName = result[i].senderName,
            sender = result[i].sender,
            action = result[i].action,
            money = result[i].money,
            date = result[i].date
        })
    end
    return History
end

function GetHistorysociety(player, society)
    local result = MySQL.query.await('SELECT * FROM yesk_history WHERE identifier = ?', {
        _type == 'self' and ESX.GetPlayerFromId(player).identifier or society
    })
    local History = {}
    for i=1, #result, 1 do
        table.insert(History, {
            senderName = result[i].senderName,
            sender = result[i].sender,
            action = result[i].action,
            money = result[i].money,
            date = result[i].date
        })
    end
    return History
end

AddEventHandler("esx:playerLoaded", function(source, xPlayer)
    repeat
        local gennum = math.random(10000000000,90000000000)
        local result = MySQL.query.await('SELECT * FROM users WHERE bankaccount = @bankaccount', {
            ['@bankaccount'] = gennum
        })
        if #result <= 0 then
            local user = MySQL.query.await('SELECT bankaccount FROM users WHERE identifier = @identifier', {
                ['@identifier'] = xPlayer.identifier
            })[1]
            if user.bankaccount == "0" then 
                MySQL.update('UPDATE users SET bankaccount = @bankaccount WHERE identifier = @identifier', {
                    ['@bankaccount'] = gennum,
                    ['@identifier'] = xPlayer.identifier
                })
            end
        end
    until(#result > 0)
    local num = getnum(source)
end)

function getnum(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    local user = MySQL.query.await('SELECT bankaccount FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    })[1]
    if user then
        return user.bankaccount
    end
end

function getnumF(account)
    local society = MySQL.query.await('SELECT bankaccount FROM addon_account WHERE name = @name', {
        ['@name'] = 'society_'..account
    })[1]
    if society then
        return society.bankaccount
    end
end

function getzmiana(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    local user = MySQL.query.await('SELECT money FROM yesk_history WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    })[1]
    if user then
        return allmoney
    end
end

ESX.RegisterServerCallback("yesk_banking:GetAccountData", function(source, cb, account)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playername = xPlayer.getName()
    local playermoneybank = xPlayer.getAccount('bank').money
    local playerjob = xPlayer.job.name
    print(Get7DaysHistory(source))

    if account == "self" then 
        local playerdata = {
            name = playername,
            money = playermoneybank,
            transactions = GetHistory(source, "self"),
            accountNumber = getnum(xPlayer.source),
            changeIn7days = Get7DaysHistory(xPlayer.source)
        }
        cb(playerdata)
    else
        local fractionmoney
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..playerjob, function(accounte)
            fractionmoney = ESX.Math.GroupDigits(accounte.money)
        end)
        local playerdata = {
            name = xPlayer.job.label,
            money = fractionmoney,
            transactions = GetHistorysociety(source, "society_"..playerjob),
            accountNumber = getnumF(xPlayer.job.name),
            changeIn7days = Get7DaySocietyHistory("society_"..playerjob)
        }
        cb(playerdata)
    end
end)

ESX.RegisterServerCallback("yesk_banking:Action", function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local kwota = tonumber(data.otherData[1])
    local konto = tonumber(data.otherData[2])
    local playermoney = xPlayer.getAccount("money").money
    local playerbank = xPlayer.getAccount("bank").money
    local playerjob = xPlayer.job.name

    local fractionmoney
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..playerjob, function(account)
        fractionmoney = account.money
    end)
    if data.account == "self" then 
        if data.action == "withdraw" then 
            if playerbank >= kwota then 
                xPlayer.addAccountMoney('money', kwota)
                xPlayer.removeAccountMoney('bank', kwota)
                AddHistory(xPlayer.source, "System", "0000000000000000000", "withdraw", kwota)
                local CallbackData = {
                    type = 'withdraw',
                }
                cb(CallbackData)
            else 
                local CallbackData = {
                    type = 'error',
                    text = 'Nie masz wystarczajaco pieniedzy'
                }
                cb(CallbackData)
            end
        elseif data.action == "transfer" then
            if playerbank >= kwota then 
                local societyname = MySQL.query.await('SELECT name, label FROM addon_account WHERE bankaccount = @bankaccount', {
                    ['@bankaccount'] = konto
                })[1]
                if societyname then
                    local societynames = societyname.name
                    local societylabel = societyname.label
                    TriggerEvent('esx_addonaccount:getSharedAccount', ''..societynames, function(account)
                        account.addMoney(kwota)
                      end)
                      xPlayer.removeAccountMoney('bank', kwota)
                      AddHistory(xPlayer.source, societylabel, konto, "withdraw", kwota) 
                      AddSocietyHistory(societynames, xPlayer.getName(), getnum(xPlayer.source), "transfer", kwota)
                      local CallbackData = {
                        type = 'transfer',
                        account = konto,
                        amount = kwota
                    }
                    cb(CallbackData)
                else
                    local user = MySQL.query.await('SELECT identifier FROM users WHERE bankaccount = @bankaccount', {
                        ['@bankaccount'] = konto
                    })[1]
                    if user then 
                        local xTarget = ESX.GetPlayerFromIdentifier(user.identifier)
                        if xTarget then 
                            xPlayer.removeAccountMoney('bank', kwota)
                            xTarget.addAccountMoney("bank", kwota)
                            AddHistory(xPlayer.source, xTarget.getName(), konto, "transfer", kwota) -- xPlayer
                            AddHistory(xTarget.source, xPlayer.getName(), getnum(xPlayer.source), "deposit", kwota) -- xtarget
                            local CallbackData = {
                                type = 'transfer',
                                account = konto,
                                amount = kwota
                            }
                            cb(CallbackData)
                        else
                            local CallbackData = {
                                type = 'error',
                                text = 'Gracz o tym numerze konta nie jest dostepny'
                            }
                            cb(CallbackData)
                        end
                    else
                        local CallbackData = {
                            type = 'error',
                            text = 'Taki numer konta nie istnieje'
                        }
                        cb(CallbackData)
                    end
                end
            else
                local CallbackData = {
                    type = 'error',
                    text = 'Nie masz wystarczajaco pieniedzy'
                }
                cb(CallbackData)
            end
        else
            if playermoney >= kwota then
                xPlayer.removeAccountMoney('money', kwota)
                xPlayer.addAccountMoney('bank', kwota)
                AddHistory(xPlayer.source, "System", "0000000000000000000", "deposit", kwota)
                local CallbackData = {
                    type = 'withdraw',
                }
                cb(CallbackData)
            else
                local CallbackData = {
                    type = 'error',
                    text = 'Nie masz wystarczajaco pieniedzy'
                }
                cb(CallbackData)
            end
        end
    else
        if data.action == "withdraw" then 
            if fractionmoney >= kwota then 
                TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..playerjob, function(account)
                    account.removeMoney(kwota)
                  end)
                  xPlayer.addAccountMoney('money', kwota)
                  AddSocietyHistory("society_"..playerjob, "System", "0000000000000000000", "withdraw", kwota)
                local CallbackData = {
                    type = 'withdraw',
                }
                cb(CallbackData)
            else
                local CallbackData = {
                    type = 'error',
                    text = 'Nie masz wystarczajaco pieniedzy'
                }
                cb(CallbackData)
            end
        elseif data.action == "transfer" then
            if fractionmoney >= kwota then 
                local societyname = MySQL.query.await('SELECT name, label FROM addon_account WHERE bankaccount = @bankaccount', {
                    ['@bankaccount'] = konto
                })[1]
                if societyname then
                    local societynames = societyname.name
                    local societylabel = societyname.label
                    TriggerEvent('esx_addonaccount:getSharedAccount', ''..societynames, function(account)
                        account.addMoney(kwota)
                        AddSocietyHistory(societynames, xPlayer.job.label, getnumF(xPlayer.job.name), "transfer", kwota)
                      end)
                      TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..playerjob, function(account)
                        account.removeMoney(kwota)
                        AddSocietyHistory("society_"..xPlayer.job.name, societylabel, konto, "withdraw", kwota)
                      end)
                      local CallbackData = {
                        type = 'transfer',
                        account = konto,
                        amount = kwota
                    }
                    cb(CallbackData)
                else
                    local user = MySQL.query.await('SELECT identifier FROM users WHERE bankaccount = @bankaccount', {
                        ['@bankaccount'] = konto
                    })[1]
                    if user then
                        local xTarget = ESX.GetPlayerFromIdentifier(user.identifier)
                        if xTarget then 
                            TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..playerjob, function(account)
                                account.removeMoney(kwota)
                              end)
                            xTarget.addAccountMoney("bank", kwota)
                            AddHistory(xPlayer.source, xPlayer.job.label, getnumF(xPlayer.job.name), "transfer", kwota) -- xPlayer
                            AddSocietyHistory("society_"..playerjob, xTarget.getName(), konto, "withdraw", kwota) -- xTarget
                            local CallbackData = {
                                type = 'transfer',
                                account = konto,
                                amount = kwota
                            }
                            cb(CallbackData)
                        else
                            local CallbackData = {
                                type = 'error',
                                text = 'Gracz o tym numerze konta nie jest dostepny'
                            }
                            cb(CallbackData)
                        end
                    else
                        local CallbackData = {
                            type = 'error',
                            text = 'Taki numer konta nie istnieje'
                        }
                        cb(CallbackData)
                    end
                end
            else    
                local CallbackData = {
                    type = 'error',
                    text = 'Nie masz wystarczajaco pieniedzy'
                }
                cb(CallbackData)
            end
        else
            if playermoney >= kwota then
                TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..playerjob, function(account)
                    account.addMoney(kwota)
                  end)
                  xPlayer.removeAccountMoney('money', kwota)
                  AddSocietyHistory("society_"..playerjob, "System", "0000000000000000000", "deposit", kwota)
                  local CallbackData = {
                    type = 'withdraw',
                }
                cb(CallbackData)
            else
                local CallbackData = {
                    type = 'error',
                    text = 'Nie masz wystarczajaco pieniedzy'
                }
                cb(CallbackData)
            end
        end
    end
end)

exports('getBankNumber', function(src)
    return getnum(src)
end)