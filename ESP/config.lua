-- File					: config.lua
-- Version				: 1.0
-- Template Created By	: Michael Aditya Sutiono
-- Date created			: 27th November 2016
-- Contact				: mike.sutiono@gmail.com
-- Description			: This file is where you define your connection parameters. e.g. WiFi SSID and password, MQTT broker host, port, etc. here
-- You may delete the comments to free some storage space.
-- You may COMPILE (become .lc) this file to free some storage space.
-- DO NOT FORGET to DELETE the .lua file after compiling

local module = {}

-- Change MYSSID and MYPASSWORD to your Wi-Fi AP SSID and password
module.SSID		= "MYSSID"
module.SSIDPass	= "MYPASSWORD"

-- Change 192.168.0.1 and 1883 to your desired MQTT broker host and port
module.HOST		= "192.168.0.1"
module.PORT		= 1883

-- ID will be used as connection identifier on the MQTT broker
-- For this template I use the chipid (not MAC) of ESP as ID
-- You may change node.chipid() to anything you want to use as ID
module.ID		= node.chipid()

-- Define username and password for MQTT broker authentication and authorization
module.username	= "mqttusername"
module.pass		= "mqttpassword"

-- Define the ENDPOINT topic path you want to use for publishing and subscribing message
-- e.g. you want to publish and subscribe to these topics:
-- house/bedroom/lamp
-- house/bedroom/fan
-- house/bedroom/ac
-- You can define the ENDPOINT as house/bedroom
-- You can define more than one ENDPOINT
module.ENDPOINT = "house/bedroom"

return module  
