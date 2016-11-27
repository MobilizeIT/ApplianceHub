-- file : config.lua
local module = {}

--module.SSID = {}  
--module.SSID["Bengkel (Bohongan)"] = "bengkel513"
--module.SSID["UMN-SmartRoom"] = "ruang519"
module.SSID = "UMN-SmartRoom"
module.SSIDPass = "ruang519"

--module.HOST = "203.7.171.50"
module.HOST = "192.168.1.50"
module.PORT = 1883

module.ID = node.chipid()
module.pass = "smb9u5709t8yfdpvu"

module.applianceType = "smb" 
module.ENDPOINT = "/"..module.applianceType
return module  
