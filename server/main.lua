ESX              = nil
local Categories = {}
local Vehicles   = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

Citizen.CreateThread(function()
	local char = Config.PlateLetters
	char = char + Config.PlateNumbers
	if Config.PlateUseSpace then char = char + 1 end

	if char > 8 then
		print(('d3x_vehicleshop: ^1WARNING^7 plate character count reached, %s/8 characters.'):format(char))
	end
	
end)

function RemoveOwnedVehicle(plate)
	MySQL.Async.execute('DELETE FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	})
end

MySQL.ready(function()
	Categories     = MySQL.Sync.fetchAll('SELECT * FROM vehicle_categories')
	local vehicles = MySQL.Sync.fetchAll('SELECT * FROM vehicles')

	for i=1, #vehicles, 1 do
		local vehicle = vehicles[i]

		for j=1, #Categories, 1 do
			if Categories[j].name == vehicle.category then
				vehicle.categoryLabel = Categories[j].label
				break
			end
		end

		table.insert(Vehicles, vehicle)
	end

	-- send information after db has loaded, making sure everyone gets vehicle information
	TriggerClientEvent('d3x_vehicleshop:sendCategories', -1, Categories)
	TriggerClientEvent('d3x_vehicleshop:sendVehicles', -1, Vehicles)
end)

RegisterServerEvent('d3x_vehicleshop:setVehicleOwned')
AddEventHandler('d3x_vehicleshop:setVehicleOwned', function (vehicleProps)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',
	{
		['@owner']   = xPlayer.identifier,
		['@plate']   = vehicleProps.plate,
		['@vehicle'] = json.encode(vehicleProps)
	}, function (rowsChanged)
		TriggerClientEvent('esx:showNotification', _source, _U('vehicle_belongs', vehicleProps.plate))
	end)
end)

RegisterServerEvent('d3x_vehicleshop:setVehicleOwnedPlayerId')
AddEventHandler('d3x_vehicleshop:setVehicleOwnedPlayerId', function (playerId, vehicleProps)
	local xPlayer = ESX.GetPlayerFromId(playerId)

	MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',
	{
		['@owner']   = xPlayer.identifier,
		['@plate']   = vehicleProps.plate,
		['@vehicle'] = json.encode(vehicleProps)
	}, function (rowsChanged)
		TriggerClientEvent('esx:showNotification', playerId, _U('vehicle_belongs', vehicleProps.plate))
	end) 
end)

RegisterServerEvent('d3x_vehicleshop:setVehicleOwnedSociety')
AddEventHandler('d3x_vehicleshop:setVehicleOwnedSociety', function (society, vehicleProps)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',
	{
		['@owner']   = 'society:' .. society,
		['@plate']   = vehicleProps.plate,
		['@vehicle'] = json.encode(vehicleProps),
	}, function (rowsChanged)

	end)
end)

ESX.RegisterServerCallback('d3x_vehicleshop:getCategories', function (source, cb)
	cb(Categories)
end)

ESX.RegisterServerCallback('d3x_vehicleshop:getVehicles', function (source, cb)
	cb(Vehicles)
end)

ESX.RegisterServerCallback('d3x_vehicleshop:buyVehicle', function (source, cb, vehicleModel)
	local xPlayer     = ESX.GetPlayerFromId(source)
	local vehicleData = nil
	local bankMoney = xPlayer.getAccount('bank').money
	print(bankMoney)
	for i=1, #Vehicles, 1 do
		if Vehicles[i].model == vehicleModel then
			vehicleData = Vehicles[i]
			break
		end
	end
	
	if xPlayer.getMoney() >= vehicleData.price then
		--xPlayer.removeMoney(vehicleData.price)
		
		
		
		
		MySQL.Async.fetchAll('SELECT * FROM vehicles WHERE model = @model', {
			['@model'] = vehicleModel,
		}, function (result)
			if result[1] then -- does the model match?
				
				local storage = result[1].storage
				
				if storage > 0 then
					
					local nstorage = storage-1
					
					MySQL.Async.execute('UPDATE vehicles SET storage=@nstorage WHERE  `model`= @car',
					{
						['@car'] = vehicleModel,
						['@nstorage'] = nstorage,
					}, function (rowsChanged)
					
					end)
					
					xPlayer.removeMoney(vehicleData.price)
				else
					cb(false)
				end
			end
			
		end)
		
		
		--[[MySQL.Async.execute('UPDATE vehicles SET storage=@nstorage WHERE  `model`= @car',
		{
			['@car'] = vehicleModel,
			['@nstorage'] = '2',
		}, function (rowsChanged)]]
		
		cb(true)
	else if bankMoney >= vehicleData.price then
		--xPlayer.setAccountMoney('bank',bankMoney-vehicleData.price)
		--print(xPlayer.getAccount('bank').money)
		
		MySQL.Async.fetchAll('SELECT * FROM vehicles WHERE model = @model', {
			['@model'] = vehicleModel,
		}, function (result)
			if result[1] then -- does the model match?
				
				local storage = result[1].storage
				
				if storage > 0 then
					
					local nstorage = storage-1
					
					MySQL.Async.execute('UPDATE vehicles SET storage=@nstorage WHERE  `model`= @car',
					{
						['@car'] = vehicleModel,
						['@nstorage'] = nstorage,
					}, function (rowsChanged)
					
					end)
					
					xPlayer.setAccountMoney('bank',bankMoney-vehicleData.price)
					print(xPlayer.getAccount('bank').money)
				else
					cb(false)
				end
			end
			
		end)
		
		cb(true)
	else
		cb(false)
	end
end
end)

ESX.RegisterServerCallback('d3x_vehicleshop:resellVehicle', function (source, cb, plate, model)
	local resellPrice = 0
	
	-- calculate the resell price
	for i=1, #Vehicles, 1 do
		if GetHashKey(Vehicles[i].model) == model then
			resellPrice = ESX.Math.Round(Vehicles[i].price / 100 * Config.ResellPercentage)
			break
		end
	end
	
	if resellPrice == 0 then
		--print(('d3x_vehicleshop: %s attempted to sell an unknown vehicle!'):format(GetPlayerIdentifiers(source)[1]))
		TriggerClientEvent('mythic_notify:client:DoHudText', source, { type = 'vermelho', text = 'Este carro não te pertence!'})
		cb(false)
	end
	
	local xPlayer = ESX.GetPlayerFromId(source)
	
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND @plate = plate', {
		['@owner'] = xPlayer.identifier,
		['@plate'] = plate
	}, function (result)
		if result[1] then -- does the owner match?
			
			local vehicle = json.decode(result[1].vehicle)
			
			if vehicle.model == model then
				if vehicle.plate == plate then
					xPlayer.addMoney(resellPrice)
					RemoveOwnedVehicle(plate)

					cb(true)
				else
					print(('d3x_vehicleshop: %s Matrícula inválida!'):format(xPlayer.identifier))
					cb(false)
				end
			else
				print(('d3x_vehicleshop: %s Modelo inválido!'):format(xPlayer.identifier))
				cb(false)
			end
		end
		
	end)
end)

ESX.RegisterServerCallback('d3x_vehicleshop:getPlayerInventory', function (source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local items   = xPlayer.inventory
	
	cb({ items = items })
end)

ESX.RegisterServerCallback('d3x_vehicleshop:isPlateTaken', function (source, cb, plate)
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function (result)
		cb(result[1] ~= nil)
	end)
end)
ESX.RegisterServerCallback('esx_vehicleshop:isPlateTaken', function (source, cb, plate)
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function (result)
		cb(result[1] ~= nil)
	end)
end)

ESX.RegisterServerCallback('d3x_vehicleshop:retrieveJobVehicles', function (source, cb, type)
	local xPlayer = ESX.GetPlayerFromId(source)
	
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND type = @type AND job = @job', {
		['@owner'] = xPlayer.identifier,
		['@type'] = type,
		['@job'] = xPlayer.job.name
	}, function (result)
		cb(result)
	end)
end)

RegisterServerEvent('d3x_vehicleshop:setJobVehicleState')
AddEventHandler('d3x_vehicleshop:setJobVehicleState', function(plate, state)
	local xPlayer = ESX.GetPlayerFromId(source)
	
	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored WHERE plate = @plate AND job = @job', {
		['@stored'] = state,
		['@plate'] = plate,
		['@job'] = xPlayer.job.name
	}, function(rowsChanged)
		if rowsChanged == 0 then
			print(('d3x_vehicleshop: %s exploited the garage!'):format(xPlayer.identifier))
		end
	end)
end)
