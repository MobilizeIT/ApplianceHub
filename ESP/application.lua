-- File					: application.lua
-- Version				: 1.0
-- Template Created By	: Michael Aditya Sutiono
-- Date created			: 27th November 2016
-- Contact				: mike.sutiono@gmail.com
-- Description			: This file is where you put your application code
-- You may delete the comments to free some storage space.
-- You may COMPILE (become .lc) this file to free some storage space.
-- DO NOT FORGET to DELETE the .lua file after compiling

-- !!IMPORTANT!!
-- You may want to check nodemcu.readthedocs.org for a more detailed description for functions and callbacks usage
-- What I recommend you to modify is marked with
--	-- MODIFY HERE
--		<thigs to modify>
--	-- END MODIFY
-- !!IMPORTANT!!

-- In this template, I use JSON formatting for data exchange between server and also Arduino (or other microcontrollers)
-- So I will require cjson here
-- You can also require other module(s) as you desired
local cjson = require "cjson"

local module = {}  

-- Define your global variables here (like shared flag or buffer)
-- Add local if you want to make the variable only accessible within this file

-- Compulsory Variables
local m						= nil
local sn					= nil
local toArduino				= ""
local fromArd				= ""
local flagDC				= false
local flagSerialSet			= false
local publishAllowed		= true

-- Your Variables
-- MODIFY HERE
local variable1				= 0
local variable2				= ""
local buffInitParams		= ""
-- END MODIFY

-- Initialize all your variables here
local function initAll()
	-- Compulsory Variables
	sn					= nil
	toArduino			= ""
	fromArd				= ""
	flagDC				= false
	publishAllowed		= true
	
	-- Your Variables
	-- MODIFY HERE
	variable1			= 0	
	variable2			= ""
	buffInitParams		= ""
	-- END MODIFY
end

-- Function for publishing data with QoS = 1, Retain = 0
-- Modified to detect stale/unresponsive/network problem that caused mqtt disconnection
-- Actually, if you read the documentation, you can use the mqtt offline callback to detect mqtt disconnection
-- But when I tested it, it didn't work as I expected
-- I tested it by disconnecting the LAN cable from my WiFi Router and unfortunately the offline callback wasn't fired at all
-- It behaves as if the connection is still on
local function publishData(topic,payload)
    flagDC = true
    m:publish(config.ENDPOINT .. topic,payload,1,0,function(conn)
        flagDC = false
    end)
end

-- Function for subscribing to a topic
local function subscribeTopic(topic)  
    m:subscribe(config.ENDPOINT .. topic,1,function(conn)
    
	end)
end

-- I need to use the MAC address (without the ':') as message identifier, so this function was made
local function convertMACToSN(mac)
	return (mac:gsub('%:', '')):sub(1,12)
end

-- Function to create connection to MQTT broker, register message callbacks, define LWT
local function mqtt_start()
	-- Initialize all variable
	initAll() 
	
	-- Define our MQTT client parameters (120 seconds keepalive time)
	m = mqtt.Client(config.ID, 120,config.username,config.pass)
	
	-- Define our message callbacks
	-- These are some examples
    m:on("message", function(conn, topic, data) 
		if (data ~= nil) then
			jobj = cjson.decode(data)
			
			-- MODIFY HERE
			if (topic == config.ENDPOINT.."/"..sn) then
				if (jobj.key1 == "desiredValue1" and jobj.key2 ~= "desiredValue2") then
					subscribeTopic("/subTopic1")
					snd = "{\"keyToSend1\":\"value1\",\"keyToSend2\":"..variable1..",\"keyToSend3\":\""..variable2.."\"}"
					publishData("/subtopic1",snd)
				end
			elseif (topic == config.ENDPOINT.."/"..owner and jobj.deviceID == sn) then
				if (jobj.key3 == "desiredValue3" and jobj.key4 ~= "desiredValue4") then
					toArduino = "{\"key5\":\""..jobj.key5.."\",\"key6\":"..jobj.key6.."}"
					print(toArduino)
				end
			end
			-- END MODIFY
			
		end
	end)
    
    -- Define LWT message. MQTT broker will publish this message to a predefined topic when the broker detects a disconnected client
	-- MODIFY HERE
	m:lwt("/lwt","{\"msg\":\"offline\",\"id\":\""..sn.."\"}",1)
	-- END MODIFY
	
	-- Connect to MQTT broker with secure line and auto reconnect
    m:connect(config.HOST, config.PORT,1 ,1, function(con)
		-- LEAVE THIS EMPTY!!
		-- Use mqtt on connect callback to define what to do next
    end) 
	
	-- Use mqtt on connect callback to define what to do next, e.g. subscribe to a topic, publish data, etc.
	m:on("connect", function(client)
        -- Compulsory Action
		flagDC = false
        publishAllowed = true
		
		-- MODIFY HERE
		subscribeTopic("/"..sn)
		snd = "{\"keyToSend1\":\"value1\",\"keyToSend2\":"..variable1.."}"
		publishData("/subtopic1")
		-- END MODIFY
	end)
end

-- This function is used to check the stale/unresponsive/network connection problem every 30 secs
local function checkFlagDC()
	if flagDC and wifi.sta.status() == 5 and wifi.sta.getip() ~= nil then
		flagDC = false
        publishAllowed = false
		-- We NEED to reconnect to our WiFi AP too when stale/unresponsive/network connection problem occurs
		-- I've tried to just close mqtt connection and recall the mqtt_start() function, but no luck in reconnecting
		wifi.sta.disconnect()
        tmr.delay(1000000)
        wifi.sta.connect()
	end
end

function module.start()
	-- Strip ':' from MAC address
	sn = convertMACToSN(wifi.sta.getmac())
	
	-- I use 9600 baudrate to communicate with Arduino
	-- I've tried 115200 and the UART communcation is unstable
	uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
	
	-- Register UART callbacks
	uart.on("data","}",function(data)
		-- Compulsory Action
		fromArd = cjson.decode(data)
		
		-- MODIFY HERE
		if(fromArd.msg=="ready") then     
			giveSN = "{\"msg\":\"setApplianceSerial\",\"applianceserial\":\""..sn.."\"}"
			print(giveSN)
		elseif(fromArd.msg=="serialSet")then
			flagSerialSet = true
			if(buffInitParams ~= "")then
				print(buffInitParams)
				buffInitParams = ""
			end
		-- END MODIFY
		
		-- Compulsory Action
		else
			if publishAllowed then
				publishData("/subTopic1",data)
			end
		end
	end,0)
	
	-- WiFi connection configuration
	wifi.setmode(wifi.STATION)
	wifi.sta.autoconnect(1)
	wifi.nullmodesleep(false)
	wifi.sleeptype(wifi.NONE_SLEEP)
	wifi.sta.config(config.SSID,config.SSIDPass)
	wifi.sta.connect()
	
	-- Register WiFi event monitor callback when device has gotten IP, start connection to broker
	wifi.eventmon.register(wifi.eventmon.STA_GOT_IP,function(T)
		mqtt_start()
	end)
	
	-- Register WiFi event monitor callback when device has disconnected from AP, close connection and reinitialize the m variable
	wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED,function(T)
		flagDC = true
        publishAllowed = false
        if(m ~= nil)then
            m:close()
            m = nil
        end
	end)
	
	-- Call checkFlagDC function to check the stale/unresponsive/network connection problem every 30 secs
	tmr.alarm(1, 30000, 1,checkFlagDC)
end

return module
