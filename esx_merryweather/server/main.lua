local rob = false
local robbers = {}
ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esx_customrob:tooFar')
AddEventHandler('esx_customrob:tooFar', function(currentStore)
	local _source = source
	local xPlayers = ESX.GetPlayers()
	rob = false

	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		
		if xPlayer.job.name == 'police' then
			--TriggerClientEvent('mythic_notify:client:SendAlert', xPlayers[i], {type = 'success', text = _U('robbery_cancelled_at', Stores[currentStore].nameOfStore)})
			TriggerClientEvent('esx_customrob:killBlip', xPlayers[i])
		end
	end

	if robbers[_source] then
		TriggerClientEvent('esx_customrob:tooFar', _source)
		robbers[_source] = nil
		TriggerClientEvent('mythic_notify:client:SendAlert', _source, {type = 'success', text = _U('robbery_cancelled_at', Stores[currentStore].nameOfStore)})
	end
end)

RegisterServerEvent('esx_customrob:robberyStarted')
AddEventHandler('esx_customrob:robberyStarted', function(currentStore)
	local _source  = source
	local xPlayer  = ESX.GetPlayerFromId(_source)
	local xPlayers = ESX.GetPlayers()

	if Stores[currentStore] then
		local store = Stores[currentStore]

		if (os.time() - store.lastRobbed) < Config.TimerBeforeNewRob and store.lastRobbed ~= 0 then
			TriggerClientEvent('mythic_notify:client:SendAlert', _source, {type = 'error', text = _U('recently_robbed', Config.TimerBeforeNewRob - (os.time() - store.lastRobbed))})
			return
		end

		local cops = 0
		for i=1, #xPlayers, 1 do
			local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
			if xPlayer.job.name == 'police' then
				cops = cops + 1
			end
		end

		if not rob then
			if cops >= Config.PoliceNumberRequired then
				rob = true

				for i=1, #xPlayers, 1 do
					local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
					if xPlayer.job.name == 'police' then
						TriggerClientEvent('mythic_notify:client:SendAlert', xPlayers[i], {type = 'error', text = _U('rob_in_prog', store.nameOfStore), length = 35000})
						TriggerClientEvent('esx_customrob:setBlip', xPlayers[i], Stores[currentStore].position)
					end
				end

				TriggerClientEvent('mythic_notify:client:SendAlert', _source, {type = 'success', text = _U('started_to_rob', store.nameOfStore)})
				TriggerClientEvent('mythic_notify:client:SendAlert', _source, {type = 'error', text = _U('alarm_triggered')})
				
				TriggerClientEvent('esx_customrob:currentlyRobbing', _source, currentStore)
				TriggerClientEvent('esx_customrob:startTimer', _source)
				
				Stores[currentStore].lastRobbed = os.time()
				robbers[_source] = currentStore

				SetTimeout(store.secondsRemaining * 1000, function()
					if robbers[_source] then
						rob = false
						--local chance = math.random(1, 100)
								
						if xPlayer then
							TriggerClientEvent('esx_customrob:robberyComplete', _source)

							if Config.GiveBlackMoney then
								xPlayer.addAccountMoney('black_money', store.reward)
							else
								--xPlayer.addMoney(store.reward)
							end
							local xPlayers, xPlayer = ESX.GetPlayers(), nil
							for i=1, #xPlayers, 1 do
								xPlayer = ESX.GetPlayerFromId(xPlayers[i])

								if xPlayer.job.name == 'police' then
									TriggerClientEvent('mythic_notify:client:SendAlert', xPlayers[i], {type = 'error', text = _U('robbery_complete_at', store.nameOfStore), length = 10000})
									TriggerClientEvent('esx_customrob:killBlip', xPlayers[i])
								end
							end
						end
					end
				end)
			else
				TriggerClientEvent('mythic_notify:client:SendAlert', _source, {type = 'error', text = _U('min_police', Config.PoliceNumberRequired), length = 10000})
			end
		else
			TriggerClientEvent('mythic_notify:client:SendAlert', _source, {type = 'error', text = _U('robbery_already'), length = 10000})
		end
	end
end)
