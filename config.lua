Config                            = {}
Config.DrawDistance               = 50.0
Config.MarkerColor                = { r = 255, g = 0, b = 0 }
Config.EnableOwnedVehicles        = true
Config.ResellPercentage           = 50

Config.Locale                     = 'en'

Config.LicenseEnable = false -- require people to own drivers license when buying vehicles? Only applies if EnablePlayerManagement is disabled. Requires esx_license

-- looks like this: 'LLL NNN'
-- The maximum plate length is 8 chars (including spaces & symbols), don't go past it!
Config.PlateLetters  = 0
Config.PlateNumbers  = 6
Config.PlateUseSpace = false

Config.Zones = {
	
	ShopEntering = {
		Pos   = vector3(-69.1733, 63.3443, 70.8910),
		Size  = vector3(1.5, 1.5, 1.0),
		Type  = 36
	},
	
	ShopOutside = {
		Pos   = vector3(-88.5224, 71.8645, 71.5784),
		Size  = vector3(1.5, 1.5, 1.0),
		Heading = 155.3460,
		Type  = -1
	},
	
	ResellVehicle = {
		Pos   = vector3(-71.1643, 92.4190, 72.1479),
		Size  = vector3(3.0, 3.0, 1.0),
		Type  = 1
	}

}

